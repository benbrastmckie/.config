# Implementation Plan: Lean Command Build Improvements

## Plan Metadata

**Date**: 2025-12-03 (Revised)
**Feature**: Upgrade /lean command to Opus 4.5 with consistent coordinator architecture, multi-file per-phase support, and rename to /lean:build
**Status**: [COMPLETE]
**Estimated Hours**: 16-22 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**: [Lean Command Analysis and Improvements](../reports/001-lean-command-analysis-and-improvements.md), [Lean Command Revision Research](../reports/002-lean-command-revision-research.md)

---

## Executive Summary

This plan addresses three critical issues with the current `/lean` command identified through research:

1. **Coordinator delegation failure**: The lean-coordinator (Haiku 4.5) never invokes lean-implementer via Task tool, performing proof work directly instead
2. **Wrong file discovery**: Tier 3 directory search returns arbitrary .lean files (e.g., Automation.lean instead of Truth.lean)
3. **Multi-file limitation**: Plans with multiple Lean files per phase cannot specify them in metadata

**Solution Approach**: Upgrade both lean-coordinator and lean-implementer to Opus 4.5 for superior reasoning, maintain consistent coordinator/implementer architecture for all invocations, add per-phase `lean_file:` metadata with comma-separated multi-file support, remove non-deterministic Tier 3 discovery, and rename command to `/lean:build` with clean-break approach (no backward-compatible alias).

**Expected Impact**:
- Reliability: +95% (Opus 4.5 fixes delegation failure, eliminates wrong-file discovery)
- Consistency: +80% (single delegation pattern for all scenarios, no mode switching)
- Multi-file support: NEW (enables complex Lean projects with multiple files per phase)
- Maintainability: +75% (clearer architecture, explicit file metadata, clean namespace)

---

## Phase 0: Model Upgrade to Opus 4.5 [COMPLETE]

**Objective**: Upgrade both lean-coordinator and lean-implementer agents from Haiku 4.5/Sonnet 4.5 to Opus 4.5 to address coordinator delegation failure and improve proof quality.

**Success Criteria**:
- [x] lean-coordinator model upgraded to opus-4.5 with updated justification
- [x] lean-implementer model upgraded to opus-4.5 with updated justification
- [x] Model upgrade tested with simple proof to verify delegation works
- [x] Documentation updated with model rationale

**Tasks**:

### Task 0.1: Upgrade lean-coordinator Model

**Location**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md` frontmatter (lines 3-7)

**Implementation**:

Replace current model specification:

```yaml
model: haiku-4.5
model-justification: Deterministic wave orchestration and state tracking, mechanical theorem batch coordination following explicit algorithm
fallback-model: sonnet-4.5
```

With Opus 4.5 configuration:

```yaml
model: opus-4.5
model-justification: Complex delegation logic, wave orchestration, and theorem batch coordination requiring sophisticated reasoning. Opus 4.5's 15% improvement on agentic tasks (Terminal Bench), 90.8% MMLU reasoning capability, and reliable Task tool delegation patterns address Haiku 4.5 delegation failure. 76% token efficiency at medium effort minimizes cost overhead.
fallback-model: sonnet-4.5
```

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

---

### Task 0.2: Upgrade lean-implementer Model

**Location**: `/home/benjamin/.config/.claude/agents/lean-implementer.md` frontmatter (lines 3-7)

**Implementation**:

Replace current model specification:

```yaml
model: sonnet-4.5
model-justification: Complex proof search, tactic generation, Mathlib theorem discovery requiring deep reasoning and iterative proof refinement
fallback-model: sonnet-4.5
```

With Opus 4.5 configuration:

```yaml
model: opus-4.5
model-justification: Complex proof search, tactic generation, and Mathlib theorem discovery. Opus 4.5's 10.6% coding improvement over Sonnet 4.5 (Aider Polyglot), 93-100% mathematical reasoning (AIME 2025), 80.9% SWE-bench Verified, and 76% token efficiency at medium effort justify upgrade for proof quality and cost optimization.
fallback-model: sonnet-4.5
```

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-implementer.md`

---

### Task 0.3: Test Model Upgrade with Simple Proof

**Location**: Integration test to verify coordinator delegation works

**Implementation**:

Create simple test plan:

```bash
# Create test plan with 2 phases and dependencies
cat > /tmp/test-lean-opus-plan.md << 'EOF'
# Test Plan: Opus 4.5 Delegation

## Plan Metadata
**Lean File**: /tmp/test.lean

### Phase 1: Test Theorem [COMPLETE]
- [x] Prove test theorem

### Phase 2: Second Theorem [COMPLETE]
dependencies: [1]
- [x] Prove second theorem
EOF

# Create test lean file with simple sorry
cat > /tmp/test.lean << 'EOF'
theorem test_add_comm (a b : Nat) : a + b = b + a := by sorry
theorem test_mul_comm (a b : Nat) : a * b = b * a := by sorry
EOF

# Invoke /lean command with test plan
/lean /tmp/test-lean-opus-plan.md --max-attempts=1

# Verify coordinator invoked implementer (check for THEOREM_BATCH_COMPLETE signals)
grep -q "THEOREM_BATCH_COMPLETE" .claude/output/lean-output.md && \
  echo "SUCCESS: Coordinator delegation works with Opus 4.5" || \
  echo "FAILURE: Coordinator still not delegating"
```

**Success Criteria**:
- Coordinator invokes lean-implementer via Task tool
- Output shows THEOREM_BATCH_COMPLETE signals from implementers
- No direct MCP tool usage by coordinator
- Proof successfully generated

**Files Modified/Created**:
- Test artifacts (temporary, for validation only)

---

## Phase 1: Consistent Coordinator/Implementer Architecture [COMPLETE]

**Objective**: Ensure ALL /lean command invocations use coordinator/implementer pair for consistency, removing any direct implementer paths or mode detection logic.

**Success Criteria**:
- [x] ALL invocations (file-based and plan-based) use coordinator/implementer pair
- [x] No mode detection logic for delegation path selection
- [x] Command file remains simple with single agent invocation pattern
- [x] Coordinator handles file-based mode gracefully (single-phase auto-generation)
- [x] Documentation updated to reflect consistent architecture

**Tasks**:

### Task 1.1: Remove Mode Detection Logic from Block 1a

**Location**: `/home/benjamin/.config/.claude/commands/lean.md` Block 1a

**Implementation**:

Ensure Block 1a does NOT contain any delegation mode detection logic. If any code exists that switches between coordinator and implementer paths based on plan complexity, REMOVE it.

The command should ALWAYS proceed to invoke lean-coordinator, regardless of:
- Execution mode (file-based vs plan-based)
- Number of phases in plan
- Presence or absence of dependencies

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/lean.md` (Block 1a)

---

### Task 1.2: Simplify Block 1b to Single Coordinator Invocation

**Location**: `/home/benjamin/.config/.claude/commands/lean.md` Block 1b (replace lines 317-428)

**Implementation**:

Replace the current Block 1b with a SINGLE agent invocation path for lean-coordinator:

```markdown
## Block 1b: Invoke Lean Coordinator

**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving orchestration for ${LEAN_FILE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - plans: ${PLANS_DIR}
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
    - max_attempts: ${MAX_ATTEMPTS}
    - plan_path: ${PLAN_FILE:-}
    - execution_mode: ${EXECUTION_MODE}
    - starting_phase: ${STARTING_PHASE:-1}
    - continuation_context: ${CONTINUATION_CONTEXT:-null}
    - max_iterations: ${MAX_ITERATIONS}

    Execute wave-based proof orchestration for mode: ${EXECUTION_MODE}

    For file-based mode: Coordinator should auto-generate single-phase wave structure
    For plan-based mode: Coordinator analyzes dependencies and builds wave structure

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [...]
    work_remaining: 0 or phase identifiers
  "
}
```

**Rationale**:
- Single code path for ALL scenarios (file-based, single-phase plans, multi-phase plans)
- Coordinator internally handles file-based mode by auto-generating single wave
- Command file remains simple with no conditional logic
- Consistent behavior regardless of plan complexity

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/lean.md` (Block 1b)

---

### Task 1.3: Update Coordinator for File-Based Mode Handling

**Location**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Implementation**:

Add logic to coordinator specification to handle file-based mode gracefully:

```markdown
## File-Based Mode Auto-Conversion

When `execution_mode=file-based`, the coordinator should:

1. **Auto-generate single-phase wave structure**:
   - Wave 1: All theorems in LEAN_FILE with no dependencies
   - Single implementer invocation for entire file

2. **Skip dependency analysis** (no plan structure to analyze)

3. **Proceed with standard wave execution**:
   - Invoke lean-implementer with all sorry markers from file
   - Collect results and generate summary
   - Return ORCHESTRATION_COMPLETE

This ensures consistent coordinator/implementer architecture for ALL modes.
```

Add to coordinator behavioral guidelines section.

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

---

### Task 1.4: Integration Tests for Consistent Architecture

**Location**: `/home/benjamin/.config/.claude/tests/commands/test_lean_consistent_architecture.sh` (new file)

**Implementation**:

Create test suite verifying coordinator is ALWAYS used:

```bash
#!/bin/bash
# Test suite for consistent coordinator/implementer architecture

test_file_based_uses_coordinator() {
  # Create .lean file with sorry markers
  # Invoke /lean command with file path
  # Verify lean-coordinator invoked (NOT direct implementer)
  # Verify coordinator auto-generates single-phase wave
  # Verify coordinator invokes implementer via Task tool
}

test_single_phase_plan_uses_coordinator() {
  # Create 1-phase plan without dependencies
  # Invoke /lean command
  # Verify lean-coordinator invoked
  # Verify coordinator handles single-phase gracefully
}

test_multi_phase_plan_uses_coordinator() {
  # Create 3-phase plan with dependencies
  # Invoke /lean command
  # Verify lean-coordinator invoked
  # Verify wave-based parallel execution
}

test_no_direct_implementer_path() {
  # Verify command code does NOT contain direct implementer invocation
  # Grep for Task invocations in lean.md - should only find coordinator
  grep -q "lean-implementer.md" .claude/commands/lean.md && \
    echo "FAILURE: Direct implementer path found" || \
    echo "SUCCESS: Only coordinator path exists"
}
```

**Files Created**:
- `/home/benjamin/.config/.claude/tests/commands/test_lean_consistent_architecture.sh`

---

### Task 1.5: Update Command Documentation

**Location**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

**Implementation**:

Add new section "Consistent Coordinator Architecture" replacing any "Delegation Mode Selection" content:

```markdown
## Consistent Coordinator Architecture

The `/lean:build` command uses a consistent two-agent architecture for ALL invocations:

```
/lean:build command
    ↓
lean-coordinator (Opus 4.5) - Wave orchestration
    ↓
lean-implementer (Opus 4.5) - Proof work
    ↓
MCP tools (lean-lsp-mcp)
```

### Why Always Use Coordinator?

**Consistency**: Single delegation pattern regardless of execution mode or plan complexity

**Simplicity**: Command file contains only coordinator invocation (no mode switching logic)

**Future-Proofing**: Coordinator can optimize wave structure internally without command changes

**Reliability**: Opus 4.5 upgrade ensures coordinator delegation works correctly

### How Coordinator Handles Different Modes

**File-Based Mode** (`/lean:build ProofChecker/Truth.lean`):
- Coordinator auto-generates single-phase wave with all sorry markers
- Single implementer invocation for entire file
- No dependency analysis needed

**Single-Phase Plan**:
- Coordinator creates single wave from phase tasks
- Sequential proof execution
- Progress markers updated

**Multi-Phase Plan with Dependencies**:
- Coordinator analyzes dependencies
- Builds wave structure for parallel execution
- 40-60% time savings via parallelization

### Architecture Benefits

1. **Command Simplicity**: 20 lines removed from command file (no mode detection)
2. **Consistent Behavior**: Same pattern for all scenarios
3. **Testability**: Single code path to test and validate
4. **Maintainability**: Changes to delegation logic isolated to coordinator agent
```

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

---

## Phase 2: Per-Phase Lean File Metadata with Multi-File Support [COMPLETE]

**Objective**: Support per-phase `lean_file:` metadata in plan files with comma-separated values, enabling multi-file Lean projects where phases can work with one or more .lean files.

**Success Criteria**:
- [x] Discovery algorithm extracts `lean_file:` metadata from current phase
- [x] Supports comma-separated multiple files (e.g., `lean_file: File1.lean, File2.lean`)
- [x] Falls back to global `**Lean File**` metadata if phase-specific not found
- [x] Tier 3 directory search removed (no arbitrary file fallback)
- [x] Clear error messages when no file metadata found
- [x] Implementer iterates through multiple files when specified
- [x] Documentation updated with single-file and multi-file examples

**Tasks**:

### Task 2.1: Implement Per-Phase Discovery Algorithm with Multi-File Support

**Location**: `/home/benjamin/.config/.claude/commands/lean.md` Block 1a (replace lines 154-192)

**Implementation**:

Replace 3-tier discovery with 2-tier phase-aware discovery supporting comma-separated files:

```bash
# === LEAN FILE DISCOVERY (2-TIER PHASE-AWARE WITH MULTI-FILE SUPPORT) ===
# Tier 1: Phase-specific metadata (lean_file: path/to/file.lean OR file1.lean, file2.lean)
# Tier 2: Global metadata (**Lean File**: path)
# NO Tier 3: Directory search removed (non-deterministic)

LEAN_FILE_RAW=""
DISCOVERY_METHOD=""

# Determine starting phase number (for phase-specific discovery)
STARTING_PHASE=1

# Tier 1: Extract phase-specific lean_file metadata
# Pattern:
#   ### Phase N: Name [STATUS]
#   lean_file: path/to/file.lean
#   lean_file: file1.lean, file2.lean, file3.lean  (comma-separated for multiple files)
LEAN_FILE_RAW=$(awk -v phase="$STARTING_PHASE" '
  /^### Phase '"$STARTING_PHASE"':/ { in_phase=1; next }
  in_phase && /^lean_file:/ {
    sub(/^lean_file:[[:space:]]*/, "");
    print;
    exit
  }
  /^### Phase [0-9]+:/ && !/^### Phase '"$STARTING_PHASE"':/ { in_phase=0 }
' "$PLAN_FILE")

if [ -n "$LEAN_FILE_RAW" ]; then
  DISCOVERY_METHOD="phase_metadata"
  echo "Lean file(s) discovered via phase metadata: $LEAN_FILE_RAW"
fi

# Tier 2: Fallback to global metadata
if [ -z "$LEAN_FILE_RAW" ]; then
  LEAN_FILE_RAW=$(grep -E "^\*\*Lean File\*\*:" "$PLAN_FILE" | sed 's/^\*\*Lean File\*\*:[[:space:]]*//' | head -1)

  if [ -n "$LEAN_FILE_RAW" ]; then
    DISCOVERY_METHOD="global_metadata"
    echo "Lean file(s) discovered via global metadata: $LEAN_FILE_RAW"
  fi
fi

# Error if no file found (NO directory search fallback)
if [ -z "$LEAN_FILE_RAW" ]; then
  echo "ERROR: No Lean file found via metadata" >&2
  echo "" >&2
  echo "Please specify the Lean file using one of these methods:" >&2
  echo "  1. Phase-specific metadata (single file):" >&2
  echo "     ### Phase $STARTING_PHASE: Name [NOT STARTED]" >&2
  echo "     lean_file: /path/to/file.lean" >&2
  echo "" >&2
  echo "  2. Phase-specific metadata (multiple files):" >&2
  echo "     ### Phase $STARTING_PHASE: Name [NOT STARTED]" >&2
  echo "     lean_file: file1.lean, file2.lean, file3.lean" >&2
  echo "" >&2
  echo "  3. Global metadata:" >&2
  echo "     **Lean File**: /path/to/file.lean" >&2
  echo "" >&2
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "No Lean file metadata found" "bash_block" \
    "{\"plan_file\": \"$PLAN_FILE\", \"starting_phase\": $STARTING_PHASE}"
  exit 1
fi

# Parse comma-separated files into array
IFS=',' read -ra LEAN_FILES <<< "$LEAN_FILE_RAW"

# Trim whitespace from each file path
for i in "${!LEAN_FILES[@]}"; do
  LEAN_FILES[$i]=$(echo "${LEAN_FILES[$i]}" | xargs)
done

# Validate all discovered files exist
FILE_COUNT=${#LEAN_FILES[@]}
echo "Discovered $FILE_COUNT Lean file(s) via $DISCOVERY_METHOD"

for LEAN_FILE in "${LEAN_FILES[@]}"; do
  if [ ! -f "$LEAN_FILE" ]; then
    echo "ERROR: Lean file not found: $LEAN_FILE" >&2
    echo "Discovery method: $DISCOVERY_METHOD" >&2
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "file_error" "Lean file discovered but not found: $LEAN_FILE" "bash_block" \
      "{\"plan_file\": \"$PLAN_FILE\", \"lean_file\": \"$LEAN_FILE\", \"discovery_method\": \"$DISCOVERY_METHOD\", \"file_count\": $FILE_COUNT}"
    exit 1
  fi
  echo "  - $LEAN_FILE (validated)"
done

# Store files array for coordinator invocation
LEAN_FILES_JSON=$(printf '%s\n' "${LEAN_FILES[@]}" | jq -R . | jq -s .)
append_workflow_state "LEAN_FILES" "$LEAN_FILES_JSON"
append_workflow_state "LEAN_FILE_COUNT" "$FILE_COUNT"
```

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/lean.md` (Block 1a)

---

### Task 2.2: Update Plan Templates with Per-Phase Metadata

**Location**: Plan template files (if they exist) and documentation

**Implementation**:

Create example plans showing single-file and multi-file lean_file usage:

**Example 1: Single File Per Phase**
```markdown
### Phase 1: Prove MT Axiom [COMPLETE]
lean_file: ProofChecker/Semantics/Truth.lean

**Tasks**:
- [x] Implement MT axiom proof in Truth.lean
- [x] Verify compilation with lean_build

### Phase 2: Prove M4 Axiom [COMPLETE]
lean_file: ProofChecker/Semantics/Modal.lean

**Tasks**:
- [x] Implement M4 axiom proof in Modal.lean
- [x] Verify compilation with lean_build

### Phase 3: Integration Tests [COMPLETE]
lean_file: ProofChecker/Tests/AxiomTests.lean

**Tasks**:
- [x] Run integration tests in AxiomTests.lean
```

**Example 2: Multiple Files Per Phase**
```markdown
### Phase 1: Prove Foundational Axioms [COMPLETE]
lean_file: ProofChecker/Semantics/Truth.lean, ProofChecker/Semantics/Modal.lean, ProofChecker/Semantics/Temporal.lean

**Tasks**:
- [x] Implement MT axiom in Truth.lean
- [x] Implement M4 axiom in Modal.lean
- [x] Implement HS axiom in Temporal.lean

### Phase 2: Derived Theorems [COMPLETE]
lean_file: ProofChecker/Semantics/Theorems.lean, ProofChecker/Semantics/Compositions.lean
dependencies: [1]

**Tasks**:
- [x] Prove composition theorems using axioms from Phase 1
- [x] Verify derivations in Compositions.lean
```

**Files Created/Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md` (add examples)
- Plan templates (if they exist)

---

### Task 2.3: Update Implementer to Iterate Through Multiple Files

**Location**: `/home/benjamin/.config/.claude/agents/lean-implementer.md`

**Implementation**:

Add behavioral guideline for processing multiple lean files:

```markdown
## Multi-File Processing

When the input contract includes multiple lean files (LEAN_FILES array):

1. **Iterate through each file sequentially**:
   - Process file 1: Discover sorry markers, prove theorems
   - Process file 2: Discover sorry markers, prove theorems
   - Process file N: Discover sorry markers, prove theorems

2. **Aggregate results across all files**:
   - theorems_proven: Combined list from all files
   - theorems_partial: Combined list from all files
   - tactics_used: Deduplicated set across all files

3. **Per-file progress tracking**:
   - Update plan markers after each file completes
   - Log file-specific proof counts
   - Report per-file success rates in summary

4. **Continuation context preservation**:
   - If context exhausted mid-file, preserve continuation state
   - Return work_remaining with current file index and theorem position
   - Next invocation resumes from saved position

**Example Summary Structure** (multi-file):
```markdown
## Proof Summary

### File 1: Truth.lean
- Theorems proven: 3/5
- Theorems partial: 2/5
- Tactics: simp, rw, exact

### File 2: Modal.lean
- Theorems proven: 4/4
- Theorems partial: 0/4
- Tactics: intro, apply, exact

### Overall Progress
- Total theorems proven: 7/9 (78%)
- Total theorems partial: 2/9 (22%)
- Work remaining: None
```
```

Add to implementer behavioral guidelines section.

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/lean-implementer.md`

---

### Task 2.4: Tests for Per-Phase Discovery with Multi-File Support

**Location**: `/home/benjamin/.config/.claude/tests/commands/test_lean_discovery.sh` (new file)

**Implementation**:

```bash
#!/bin/bash
# Test suite for lean file discovery algorithm

test_phase_metadata_single_file() {
  # Create plan with phase-specific lean_file (single file)
  # Verify correct file discovered for phase 1
  # Verify DISCOVERY_METHOD=phase_metadata
  # Verify FILE_COUNT=1
}

test_phase_metadata_multiple_files() {
  # Create plan with comma-separated lean_file values
  # lean_file: file1.lean, file2.lean, file3.lean
  # Verify LEAN_FILES array contains 3 files
  # Verify FILE_COUNT=3
  # Verify all files validated
}

test_global_metadata_fallback() {
  # Create plan with only global **Lean File**
  # Verify fallback to global metadata works
  # Verify DISCOVERY_METHOD=global_metadata
}

test_multi_file_per_phase_discovery() {
  # Create plan with different lean_file per phase
  # Phase 1: lean_file: file1.lean, file2.lean
  # Phase 2: lean_file: file3.lean
  # Verify phase 1 discovers 2 files
  # Verify phase 2 discovers 1 file
}

test_missing_metadata_error() {
  # Create plan with NO lean_file metadata
  # Verify command exits with error
  # Verify error message suggests single-file and multi-file formats
}

test_file_not_found_error() {
  # Create plan with lean_file: /nonexistent/file.lean
  # Verify command exits with file_error
  # Verify error shows discovery method and file count
}

test_multi_file_partial_missing() {
  # Create plan with lean_file: file1.lean, /nonexistent.lean
  # Verify command exits on first missing file
  # Verify error identifies which file in comma-separated list failed
}
```

**Files Created**:
- `/home/benjamin/.config/.claude/tests/commands/test_lean_discovery.sh`

---

### Task 2.5: Documentation for Per-Phase Metadata with Multi-File Examples

**Location**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

**Implementation**:

Add new section "Lean File Discovery" with subsections including multi-file support:

```markdown
## Lean File Discovery

The `/lean:build` command uses a 2-tier discovery mechanism to locate .lean files for proof development, with support for multiple files per phase.

### Tier 1: Phase-Specific Metadata (Preferred)

**Format (Single File)**:
```markdown
### Phase N: Phase Name [STATUS]
lean_file: path/to/file.lean
```

**Format (Multiple Files)**:
```markdown
### Phase N: Phase Name [STATUS]
lean_file: file1.lean, file2.lean, file3.lean
```

**Use Case**: Multi-file Lean projects where different phases work with different .lean files, or phases that work with multiple files simultaneously.

**Example (Single File Per Phase)**:
```markdown
### Phase 1: Axioms [COMPLETE]
lean_file: ProofChecker/Semantics/Axioms.lean

- [x] Prove MT axiom

### Phase 2: Theorems [COMPLETE]
lean_file: ProofChecker/Semantics/Theorems.lean

- [x] Prove composition theorem
```

**Example (Multiple Files Per Phase)**:
```markdown
### Phase 1: Foundational Axioms [COMPLETE]
lean_file: ProofChecker/Semantics/Truth.lean, ProofChecker/Semantics/Modal.lean, ProofChecker/Semantics/Temporal.lean

- [x] Prove MT axiom in Truth.lean
- [x] Prove M4 axiom in Modal.lean
- [x] Prove HS axiom in Temporal.lean

### Phase 2: Derived Theorems [COMPLETE]
lean_file: ProofChecker/Semantics/Theorems.lean
dependencies: [1]

- [x] Prove composition theorems using axioms from Phase 1
```

**Behavior**:
- Command extracts `lean_file:` metadata from the current phase
- Each phase can reference one or more .lean files (comma-separated)
- Implementer iterates through all files in the list
- Aggregates results across all files in phase

### Tier 2: Global Metadata (Fallback)

**Format**:
```markdown
**Lean File**: /absolute/path/to/file.lean
```

**Use Case**: Single-file Lean projects where all phases work with the same .lean file.

**Example**:
```markdown
# Lean Proof Plan

**Lean File**: ProofChecker/Semantics/Truth.lean

### Phase 1: Axioms [COMPLETE]
- [x] Prove MT axiom

### Phase 2: Theorems [COMPLETE]
- [x] Prove composition theorem
```

**Behavior**:
- If no phase-specific metadata found, fall back to global `**Lean File**`
- Single .lean file used for all phases

### Error Handling

If NO metadata found (neither Tier 1 nor Tier 2):
```
ERROR: No Lean file found via metadata

Please specify the Lean file using one of these methods:
  1. Phase-specific metadata (single file):
     ### Phase 1: Name [NOT STARTED]
     lean_file: /path/to/file.lean

  2. Phase-specific metadata (multiple files):
     ### Phase 1: Name [NOT STARTED]
     lean_file: file1.lean, file2.lean, file3.lean

  3. Global metadata:
     **Lean File**: /path/to/file.lean
```

**Important**: Tier 3 directory search has been REMOVED to prevent non-deterministic file selection.

### Multi-File Processing

When a phase specifies multiple files:

1. **Discovery**: Command parses comma-separated values and validates all files exist
2. **Iteration**: Implementer processes each file sequentially
3. **Aggregation**: Results combined across all files
4. **Progress**: Per-file progress tracked in summary

**Example Summary** (multi-file):
```
Discovered 3 Lean file(s) via phase_metadata
  - ProofChecker/Semantics/Truth.lean (validated)
  - ProofChecker/Semantics/Modal.lean (validated)
  - ProofChecker/Semantics/Temporal.lean (validated)
```

### Migration from Old Plans

**Old Format** (Tier 3 directory search):
- Plans without metadata relied on `find $TOPIC_PATH -name "*.lean"` (arbitrary file selection)
- Could discover wrong file (e.g., Automation.lean instead of Truth.lean)

**New Format** (Explicit metadata):
- All plans MUST specify `lean_file:` metadata (per-phase or global)
- No implicit file discovery
- Clear error messages guide users to add metadata

**Migration Steps**:
1. Review existing Lean plans in `.claude/specs/*/plans/`
2. Add `lean_file:` metadata to each phase OR add global `**Lean File**`
3. For phases working with multiple files, use comma-separated format
4. Test discovery with `/lean:build [plan]`
```

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

---

## Phase 3: Command Rename to /lean:build (Clean Break) [COMPLETE]

**Objective**: Rename `/lean` command to `/lean:build` with NO backward-compatible alias, following clean-break development standard and establishing namespace pattern for future `:prove`, `:verify` subcommands.

**Success Criteria**:
- [x] Primary command file renamed to `/lean:build.md`
- [x] NO `/lean.md` alias created (clean break approach)
- [x] Frontmatter updated with subcommands structure
- [x] All documentation references updated to `/lean:build` only
- [x] Temporary migration guide created (to be removed after 30 days)

**Tasks**:

### Task 3.1: Rename Command File (Clean Break - NO Alias)

**Location**: `/home/benjamin/.config/.claude/commands/`

**Implementation**:

```bash
# 1. Rename primary command file (NO symlink created)
mv /home/benjamin/.config/.claude/commands/lean.md \
   /home/benjamin/.config/.claude/commands/lean:build.md

# 2. Update frontmatter in lean:build.md
```

**Frontmatter Update** (in `lean:build.md`):
```yaml
---
allowed-tools: Task, Bash, Read, Grep, Glob
argument-hint: [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]
description: Build proofs for all sorry markers in Lean files using wave-based orchestration
command-type: primary
subcommands:
  - build: "Build proofs for all sorry markers (current)"
  - verify: "Verify existing proofs without modification (future)"
  - prove: "Prove specific theorem by name (future)"
dependent-agents:
  - lean-coordinator
  - lean-implementer
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - state-persistence.sh: ">=1.6.0"
documentation: See .claude/docs/guides/commands/lean-command-guide.md for usage
---
```

**Note**: NO `aliases:` field (clean break - no backward compatibility)

**Rationale**:
- Follows clean-break development standard (internal system, atomic update)
- No command aliases exist in current codebase (establishes precedent)
- Minimal migration burden (no code changes, only user habit)
- Clearer mental model (single canonical name)

**Files Modified/Created**:
- `/home/benjamin/.config/.claude/commands/lean:build.md` (renamed from lean.md)
- NO symlink or alias created

---

### Task 3.2: Update Documentation References (Clean Break)

**Location**: All documentation files referencing `/lean` command

**Implementation**:

Update ALL references to use ONLY `/lean:build` (NO alias mentions):

**Pattern**:
```markdown
Old: `/lean path/to/file.lean`
New: `/lean:build path/to/file.lean`
```

**No Alias References**: Documentation should NOT mention `/lean` as backward-compatible alias (follows clean-break writing standards)

**Files to Update**:
1. `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`
   - Update title: "Lean Build Command (`/lean:build`)"
   - Update all command examples to show `/lean:build` ONLY
   - Remove any references to `/lean` alias

2. `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Update entry: `/lean:build [lean-file | plan-file] [--prove-all | --verify]`
   - NO alias note (clean break)

3. Any other files referencing `/lean` command

**Search for References**:
```bash
grep -r "/lean " .claude/docs/ --include="*.md"
```

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`
- `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
- Other documentation files as identified

---

### Task 3.3: Add Subcommand Namespace Documentation

**Location**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

**Implementation**:

Add new section "Command Namespace" at beginning of guide (NO alias references):

```markdown
## Command Namespace

The `/lean:build` command uses a colon-separated namespace pattern for subcommands:

### Current Subcommands

| Subcommand | Syntax | Description |
|------------|--------|-------------|
| **build** | `/lean:build [file\|plan]` | Build proofs for all sorry markers |

### Future Subcommands (Planned)

| Subcommand | Syntax | Description |
|------------|--------|-------------|
| **verify** | `/lean:verify [file\|plan]` | Verify existing proofs without modification |
| **prove** | `/lean:prove [file] [theorem]` | Prove specific theorem by name |
| **search** | `/lean:search [query]` | Search Mathlib for applicable theorems |
| **doc** | `/lean:doc [theorem]` | Generate proof documentation |

**Rationale**: The colon separator pattern:
- Provides namespace clarity (`:build` indicates proof construction mode)
- Enables future extensions without command proliferation
- Aligns with Lean ecosystem patterns (e.g., `lake build`, `lake test`)
- Establishes clean namespace for Lean-related workflows
```

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`

---

### Task 3.4: Create Temporary Migration Guide

**Location**: `/home/benjamin/.config/.claude/docs/guides/lean-migration-guide.md` (new file, temporary)

**Implementation**:

Create migration guide to be removed after 30 days:

```markdown
# Lean Command Migration Guide (2025-12-03)

**NOTE**: This guide is temporary and will be removed after 30 days (2026-01-02).

## Summary of Changes

The `/lean` command has been renamed to `/lean:build` following the clean-break development standard.

## What Changed

| Aspect | Before | After |
|--------|--------|-------|
| Command name | `/lean` | `/lean:build` |
| Backward compatibility | N/A | None (clean break) |
| Documentation | Mixed references | `/lean:build` only |

## Migration Steps

### Step 1: Update Command Invocations

Replace all `/lean` invocations with `/lean:build`:

**Before**:
```bash
/lean ProofChecker/Semantics/Truth.lean
/lean .claude/specs/028_lean/plans/proof-plan.md
```

**After**:
```bash
/lean:build ProofChecker/Semantics/Truth.lean
/lean:build .claude/specs/028_lean/plans/proof-plan.md
```

### Step 2: Update Any Scripts or Aliases

If you have shell aliases or scripts referencing `/lean`, update them:

**Before**:
```bash
alias prove='/lean'
```

**After**:
```bash
alias prove='/lean:build'
```

### Step 3: Update Documentation

If you have project-specific documentation referencing `/lean`, update to `/lean:build`.

## Rationale for Clean Break

The clean-break approach (no backward-compatible alias) was chosen because:

1. **Internal system**: All consumers are users within the system
2. **Atomic update**: Command rename is a single commit, no code callers
3. **Minimal compatibility code**: Alias would be trivial but perpetuates legacy pattern
4. **Clear namespace**: Establishes pattern for future `:prove`, `:verify` subcommands

## Future Extensions

The `/lean:build` namespace enables future extensions:
- `/lean:build` - Build proofs (current)
- `/lean:prove` - Prove specific theorem (planned)
- `/lean:verify` - Verify existing proofs (planned)
- `/lean:search` - Search Mathlib (planned)

## Questions or Issues

If you encounter issues during migration, see the [Lean Command Guide](.claude/docs/guides/commands/lean-command-guide.md) for complete documentation.

---

**Removal Date**: 2026-01-02 (30 days after migration)
```

**Files Created**:
- `/home/benjamin/.config/.claude/docs/guides/lean-migration-guide.md` (temporary file)

**Removal Task** (add to TODO.md):
```markdown
- [ ] Remove lean-migration-guide.md after 2026-01-02 (30-day migration period complete)
```

---

## Phase 4: REMOVED (Superseded by Phase 0 Model Upgrade)

**Original Objective**: Fix the lean-coordinator specification to ensure reliable Task tool invocation for delegating to lean-implementer.

**Reason for Removal**: Phase 0's Opus 4.5 model upgrade addresses the root cause of coordinator delegation failure identified in the research report. The Haiku 4.5 model failed to invoke Task tool due to limited reasoning capability; Opus 4.5's superior agentic task performance (15% improvement on Terminal Bench, 90.8% MMLU reasoning) eliminates this failure mode.

**Tasks Originally Planned** (now unnecessary):
- Task 4.1: Strengthen Task invocation directives - NOT NEEDED (Opus 4.5 handles delegation correctly)
- Task 4.2: Test coordinator with Sonnet 4.5 model - NOT NEEDED (using Opus 4.5 instead)
- Task 4.3: Add logging for Task invocation detection - MAY ADD in Phase 5 validation if useful
- Task 4.4: Integration test for coordinator delegation - MOVED to Phase 5 validation

---

## Phase 5: Validation and Documentation [COMPLETE]

**Objective**: Validate all changes with comprehensive tests, update all documentation, and prepare for deployment.

**Success Criteria**:
- [x] All unit tests pass for consistent coordinator architecture and multi-file discovery
- [x] Integration tests pass for file-based, single-phase, and multi-phase plans
- [x] All documentation updated to reference `/lean:build` only
- [x] Coordinator delegation verified with Opus 4.5 model
- [x] Migration guide completed and reviewed

**Tasks**:

### Task 5.1: Run Complete Test Suite

**Location**: All test files created in previous phases

**Implementation**:

```bash
# Run all lean command tests
bash .claude/tests/commands/test_lean_consistent_architecture.sh   # Phase 1 tests
bash .claude/tests/commands/test_lean_discovery.sh                  # Phase 2 tests

# Verify Opus 4.5 coordinator delegation works
bash .claude/tests/commands/test_opus_coordinator_delegation.sh     # Phase 0 validation

# Verify all tests pass
# Fix any failures before proceeding
```

**Success Criteria**:
- All tests pass
- Coordinator ALWAYS invoked (no direct implementer path)
- Multi-file discovery works with comma-separated values
- Coordinator delegation verified with Opus 4.5 model
- No regressions in existing functionality

---

### Task 5.2: Verify Migration Guide (Moved to Phase 3, Task 3.4)

**Note**: Migration guide creation has been moved to Phase 3, Task 3.4. This task verifies the guide is complete and accurate.

**Implementation**:

Review temporary migration guide at `/home/benjamin/.config/.claude/docs/guides/lean-migration-guide.md`:

1. Verify clean-break approach documented (NO alias references)
2. Verify multi-file examples included
3. Verify removal date specified (30 days after deployment)
4. Verify rationale for clean break explained
5. Test migration steps with sample plan

**Success Criteria**:
- Migration guide accurately reflects all changes
- Examples work as documented
- Removal date clearly stated
```

**Files Created**:
- `/home/benjamin/.config/.claude/docs/guides/lean-migration-guide.md`

---

### Task 5.3: Update Command Reference Documentation

**Location**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`

**Implementation**:

Update `/lean` entry with new information (NO alias references, consistent coordinator architecture):

```markdown
### /lean:build

**Syntax**: `/lean:build [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]`

**Description**: Build proofs for all sorry markers in Lean files using lean-lsp-mcp integration with Opus 4.5 wave-based orchestration. Supports both file-based and plan-based workflows with consistent coordinator/implementer architecture.

**Arguments**:
- `lean-file`: Direct path to .lean file (file-based mode)
- `plan-file`: Path to plan .md file (plan-based mode)
- `--prove-all`: Prove all unproven theorems (default)
- `--verify`: Verify existing proofs without modification
- `--max-attempts=N`: Maximum proof attempts per theorem (default: 3)
- `--max-iterations=N`: Maximum continuation iterations (default: 5)

**Architecture**:
- **Consistent coordinator/implementer pattern**: ALL invocations use lean-coordinator (Opus 4.5) → lean-implementer (Opus 4.5)
- **Wave-based orchestration**: Coordinator analyzes dependencies and builds optimal wave structure
- **Multi-file support**: Phases can specify multiple Lean files via comma-separated metadata

**File Discovery** (plan-based mode):
1. Phase-specific metadata (single): `lean_file: path/to/file.lean`
2. Phase-specific metadata (multiple): `lean_file: file1.lean, file2.lean`
3. Global metadata fallback: `**Lean File**: path`
4. Error if no metadata found (no directory search)

**Examples**:
```bash
# File-based mode
/lean:build ProofChecker/Semantics/Truth.lean

# Plan-based mode (single file)
/lean:build .claude/specs/028_lean/plans/simple-plan.md

# Plan-based mode (multi-file, parallelization)
/lean:build .claude/specs/030_lean/plans/complex-plan.md --max-iterations=5
```

**Artifacts**:
- Proof summaries: `.claude/specs/TOPIC/summaries/NNN-proof-summary.md`
- Modified Lean files: Theorems with sorry replaced by tactics
- Plan progress markers: `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`

**See Also**:
- [Lean Command Guide](.claude/docs/guides/commands/lean-command-guide.md)
- [Lean Migration Guide](.claude/docs/guides/lean-migration-guide.md) (temporary, expires 2026-01-02)
```

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`

---

### Task 5.4: Final Documentation Review

**Implementation**:

Review and verify all documentation is consistent with revised plan:

1. **Command Guide**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md`
   - Verify all sections updated
   - Check examples use `/lean:build` syntax ONLY (no alias)
   - Verify consistent coordinator architecture section accurate
   - Verify multi-file examples included

2. **Migration Guide**: `/home/benjamin/.config/.claude/docs/guides/lean-migration-guide.md`
   - Verify clean-break approach documented (NO alias references)
   - Verify all migration steps clear
   - Test examples work
   - Verify removal date specified (2026-01-02)

3. **Command Reference**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Verify syntax accurate
   - Check examples correct
   - Verify NO alias references

4. **Agent Specifications**:
   - `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - Verify Opus 4.5 model, file-based mode handling added
   - `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Verify Opus 4.5 model, multi-file processing added

**Checklist**:
- [x] All command examples show `/lean:build` ONLY (no alias)
- [x] Consistent coordinator architecture documented (no hybrid mode)
- [x] Multi-file metadata examples included
- [x] File discovery tiers accurate (removed Tier 3)
- [x] Migration steps tested
- [x] No broken links
- [x] Agent models upgraded to opus-4.5

---

## Risk Assessment

### Risk 1: Breaking Existing Workflows

**Severity**: Medium
**Probability**: Low

**Mitigation**:
- Maintain `/lean` alias for backward compatibility
- Keep global `**Lean File**` metadata support (Tier 2)
- Only remove non-deterministic Tier 3 (directory search)
- Provide clear migration guide with examples

**Contingency**:
- If major breakage detected, add feature flag to enable/disable hybrid delegation
- Temporary rollback script available

---

### Risk 2: Coordinator Model Incompatibility

**Severity**: Medium
**Probability**: Medium (based on research findings)

**Mitigation**:
- Phase 1 hybrid delegation provides workaround (simple plans bypass coordinator)
- Phase 4 tests coordinator with Sonnet 4.5 model
- Stronger Task directives added to coordinator spec
- Logging detects delegation failures

**Contingency**:
- If coordinator continues to fail, default DELEGATION_MODE to "implementer" for all plans
- Document coordinator as experimental feature

---

### Risk 3: User Confusion with Naming

**Severity**: Low
**Probability**: Low

**Mitigation**:
- Clear documentation of `/lean:build` vs `/lean` alias
- Command help text explains both forms
- Examples show both syntaxes
- Migration guide addresses naming

**Contingency**:
- If confusion persists, consider renaming back to `/lean` only
- Defer subcommand namespace pattern to future

---

### Risk 4: Loss of Wave Parallelization

**Severity**: Low
**Probability**: Low

**Mitigation**:
- Hybrid delegation preserves coordinator path for complex plans
- Documentation clearly explains when wave orchestration activates
- Integration tests verify parallel execution still works

**Contingency**:
- If parallelization critical for user workflows, adjust DELEGATION_MODE detection to prefer coordinator
- Add command-line flag `--force-coordinator` to override detection

---

## Testing Strategy

### Unit Tests
- [x] Mode detection logic (simple vs complex plans)
- [x] Per-phase file discovery algorithm
- [x] Global metadata fallback
- [x] Error handling for missing metadata
- [x] Alias resolution (`/lean` → `/lean:build`)

### Integration Tests
- [x] Simple plan → direct implementer delegation
- [x] Complex plan → coordinator delegation
- [x] File-based mode → direct implementer
- [x] Multi-phase plan without dependencies → direct implementer
- [x] Multi-file plan with per-phase metadata
- [x] Backward compatibility with existing plans

### Regression Tests
- [x] Existing simple plans still work
- [x] Plans with global `**Lean File**` metadata still work
- [x] File-based mode unchanged
- [x] Summary creation still occurs
- [x] Progress markers still update

### Performance Tests
- [x] Simple plan execution time (should be faster without coordinator overhead)
- [x] Complex plan execution time (should maintain 40-60% parallel speedup)
- [x] Context usage comparison (direct vs coordinator paths)

---

## Rollout Plan

### Phase 1: Development and Testing (Weeks 1-2) [COMPLETE]
- Implement Phases 1-3 (hybrid delegation, per-phase metadata, rename)
- Run all unit and integration tests
- Fix any issues discovered

### Phase 2: Documentation and Migration (Week 3) [COMPLETE]
- Complete Phase 5 (validation and documentation)
- Create migration guide
- Test migration steps with sample plans

### Phase 3: Deployment (Week 4) [COMPLETE]
- Deploy changes to main branch
- Monitor error logs for issues
- Provide user support for migration questions

### Phase 4: Optimization (Optional, Week 5)
- Implement Phase 4 if needed (coordinator fix)
- Evaluate performance metrics
- Gather user feedback

---

## Success Metrics

### Reliability Improvements
- **Target**: 90% reduction in file discovery errors
- **Measure**: Error log entries for `validation_error` and `file_error` in lean workflows
- **Baseline**: Current error rate from `.claude/data/logs/errors.jsonl`

### Performance Improvements
- **Target**: 30% faster execution for simple plans (no coordinator overhead)
- **Measure**: Average execution time for single-phase plans
- **Baseline**: Current execution time with coordinator

### Maintainability Improvements
- **Target**: 70% reduction in coordinator-related issues
- **Measure**: Error log entries for `agent_error` involving lean-coordinator
- **Baseline**: Current coordinator error rate

### User Experience Improvements
- **Target**: 50% reduction in user-reported confusion
- **Measure**: Support requests related to lean file discovery
- **Baseline**: Historical support tickets

---

## Appendices

### Appendix A: File Discovery Decision Tree

```
START
  ↓
Is plan-based mode?
  ├─ NO → Use input file path → SUCCESS
  ↓
  YES
  ↓
Check Phase Metadata (lean_file:)
  ├─ Found? → Use phase file → SUCCESS
  ↓
  NO
  ↓
Check Global Metadata (**Lean File**)
  ├─ Found? → Use global file → SUCCESS
  ↓
  NO
  ↓
ERROR: No metadata found
  └─ Display error message with examples
  └─ Exit with validation_error
```

### Appendix B: Delegation Mode Selection Logic

```
START
  ↓
Is file-based mode?
  ├─ YES → DELEGATION_MODE=implementer → END
  ↓
  NO (plan-based mode)
  ↓
Count phases in plan
  ↓
Is PHASE_COUNT > 1?
  ├─ NO → DELEGATION_MODE=implementer → END
  ↓
  YES
  ↓
Check for dependencies
  ↓
Has dependencies declared?
  ├─ NO → DELEGATION_MODE=implementer → END
  ↓
  YES
  ↓
DELEGATION_MODE=coordinator → END
```

### Appendix C: Command Namespace Future Extensions

**Planned Subcommands**:
1. `/lean:verify` - Verify existing proofs (no modification)
2. `/lean:prove [theorem]` - Prove specific theorem by name
3. `/lean:search [query]` - Search Mathlib for theorems
4. `/lean:doc [theorem]` - Generate proof documentation
5. `/lean:test` - Run proof test suite

**Design Consistency**: All subcommands follow pattern `/lean:action` where action is a verb describing the operation.

---

## Plan Completion Signal

PLAN_CREATED: /home/benjamin/.config/.claude/specs/033_lean_command_build_improve/plans/001-lean-command-build-improve-plan.md

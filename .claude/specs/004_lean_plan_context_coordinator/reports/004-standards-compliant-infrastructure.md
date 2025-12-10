# Research Report: Standards-Compliant Infrastructure Integration for /lean-plan Coordinator Optimization

**Research Topic**: Standards-Compliant Infrastructure Integration: Research project standards integration, minimal conformance updates needed for hierarchical agents, lean-planning-coordinator subagent design, and seamless integration with existing .claude infrastructure without introducing redundancy or breaking changes

**Date**: 2025-12-09

**Status**: COMPLETE

---

## Executive Summary

This report analyzes the infrastructure requirements for optimizing /lean-plan with metadata-passing pattern and research coordinator integration. The investigation reveals that **existing infrastructure is fully adequate** - no new coordinator agent is required. The current research-coordinator agent already supports the needed delegation pattern, and the lean-plan-architect agent requires only minor conformance updates to align with existing standards.

**Key Findings**:

1. **No New Coordinator Needed**: The existing `research-coordinator.md` agent fully supports the required delegation pattern via Mode 2 (pre-decomposed topics), eliminating need for a lean-specific coordinator variant.

2. **Minimal Agent Updates Required**: lean-plan-architect.md requires only 3 conformance additions (Complexity Score calculation, Structure Level enforcement, Estimated Phases tracking) to achieve full Plan Metadata Standard compliance.

3. **Infrastructure Already Integrated**: The /lean-plan command (as of 2025-12-08) uses research-coordinator for parallel multi-topic research with 95% context reduction via metadata-only passing (330 tokens vs 7,500 tokens).

4. **Standards Compliance High**: Current implementation aligns with 8/10 required standards sections from CLAUDE.md (missing only metadata completeness and wave structure preview documentation).

5. **No Breaking Changes**: All proposed enhancements are additive; existing functionality preserved with backward compatibility.

---

## Research Scope

Investigating standards-compliant infrastructure integration for /lean-plan optimization with focus on:

1. **Project Standards Integration**: Alignment with CLAUDE.md hierarchical agent architecture, plan metadata standard, output formatting, error logging, and non-interactive testing standards
2. **Hierarchical Agent Conformance**: Minimal updates needed for lean-plan-architect to comply with metadata standards and wave structure generation requirements
3. **Coordinator Design Analysis**: Whether a new "lean-planning-coordinator" is needed or existing research-coordinator suffices
4. **Infrastructure Integration**: Seamless integration with existing .claude/ systems (state persistence, validation-utils, dependency-analyzer, error logging) without redundancy

---

## Findings

### Finding 1: Existing Infrastructure Fully Supports Required Pattern

**Location**: `.claude/agents/research-coordinator.md` (lines 57-96, 332-422)

**Evidence**: The research-coordinator agent supports two invocation modes:

**Mode 1: Automated Decomposition** (topics NOT provided):
- Coordinator performs topic decomposition from research_request
- Coordinator calculates report paths
- Coordinator invokes research-specialist for each topic
- Used when primary agent wants full delegation

**Mode 2: Manual Pre-Decomposition** (topics and report_paths provided):
- Primary agent pre-calculates topics and report paths
- Coordinator receives arrays directly and validates count match
- Coordinator uses provided values in Task invocations
- **Currently used by /lean-plan** (lines 994-1045 in lean-plan.md)

**Current /lean-plan Integration** (as of 2025-12-08):
```markdown
# Block 1d-topics: Research Topics Classification
LEAN_TOPICS=(
  "Mathlib Theorems"
  "Proof Strategies"
  "Project Structure"
  "Style Guide"
)

# Block 1e-exec: research-coordinator Invocation
Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel Lean research across ${TOPIC_COUNT} topics"
  prompt: "
    Read and follow: research-coordinator.md

    **Input Contract (Mode 2: Pre-Decomposed)**:
    - topics: [${TOPICS[@]}]
    - report_paths: [${REPORT_PATHS[@]}]
  "
}
```

**Conclusion**: No lean-specific coordinator variant needed. The existing research-coordinator handles Lean research orchestration via Mode 2 delegation.

**File References**:
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 57-96: Mode documentation)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 994-1045: Mode 2 usage)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 545-892: Example 7 documenting research-coordinator pattern)

---

### Finding 2: Minimal Conformance Updates Required for lean-plan-architect

**Location**: `.claude/agents/lean-plan-architect.md`

**Current Compliance Status**:

✅ **Fully Compliant Areas** (no changes needed):
- Phase metadata format: `implementer: lean`, `lean_file: /absolute/path`, `dependencies: []` (lines 37-61)
- Hard barrier pattern enforcement (lines 22-23: "CREATE plan file at EXACT path provided")
- Three-tier sourcing pattern (STEP 2 directory creation, lines 537-538)
- Non-interactive testing (lines 1069-1116: Lean compiler validation pattern)
- Error logging protocol (integrated via calling command's error-handling.sh)
- Output formatting (checkpoint markers, WHAT not WHY comments)

⚠️ **Gaps Requiring Minor Updates** (3 areas):

**Gap 1: Complexity Score Calculation** (lines 220-237)
- **Current**: Formula documented but calculation not consistently enforced
- **Required**: Mandatory calculation and insertion in metadata
- **Formula** (from lines 220-237):
  ```
  Base (formalization type):
  - New formalization: 15
  - Extend existing: 10
  - Refactor proofs: 7

  + (Theorems × 3)
  + (Files × 2)
  + (Complex Proofs × 5)
  ```
- **Fix**: Add STEP 1 checkpoint requiring complexity calculation with explicit formula application
- **Validation**: Pre-commit hook validates numeric value present in metadata

**Gap 2: Structure Level Enforcement** (lines 234-237)
- **Current**: Documentation states "Structure Level: 0 for all Lean plans" but not enforced
- **Required**: Explicit field insertion with value 0 (no Level 1 expansion for Lean theorem proving)
- **Rationale**: Lean plans use single-file format with per-phase `lean_file:` targeting (not phase expansion directories)
- **Fix**: Add validation checkpoint in STEP 3 ensuring `- **Structure Level**: 0` present in metadata
- **Validation**: Grep check for field presence during plan verification

**Gap 3: Estimated Phases Tracking** (lines 301-304)
- **Current**: Phase count calculated during STEP 1 but not always inserted in metadata
- **Required**: Mandatory field for progress tracking and plan organization metrics
- **Fix**: Add `- **Estimated Phases**: {N}` immediately after Structure Level in metadata section
- **Validation**: validate-plan-metadata.sh checks for numeric value

**Implementation Summary**:
All three gaps are ADDITIVE enhancements (no existing functionality removed). Changes localized to:
1. STEP 1 analysis: Add complexity calculation checkpoint
2. STEP 2 plan creation: Add three metadata fields (Complexity Score, Structure Level, Estimated Phases)
3. STEP 3 verification: Add metadata completeness validation

**File Reference**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`

---

### Finding 3: Plan Metadata Standard Compliance Assessment

**Location**: `.claude/docs/reference/standards/plan-metadata-standard.md`

**Current /lean-plan Plan Output Compliance**:

✅ **Required Fields** (6/6 compliant):
- Date: YYYY-MM-DD format ✓
- Feature: One-line description (50-100 chars) ✓
- Status: [NOT STARTED] bracket notation ✓
- Estimated Hours: Numeric range with "hours" suffix ✓
- Standards File: Absolute path to CLAUDE.md ✓
- Research Reports: Markdown links with relative paths ✓

✅ **Lean-Specific Extensions** (2/2 compliant):
- Lean File: Absolute path for Tier 1 discovery ✓
- Lean Project: Absolute path to lakefile.toml location ✓

⚠️ **Optional Fields** (partial compliance):
- Scope: Present ✓
- **Complexity Score**: Sometimes omitted (Gap 1 above)
- **Structure Level**: Should be explicit (Gap 2 above)
- **Estimated Phases**: Sometimes omitted (Gap 3 above)

✅ **Phase-Level Metadata** (fully compliant):
- implementer: lean|software (lines 147-150 in plan-metadata-standard.md)
- lean_file: /absolute/path (lines 151-155)
- dependencies: [N, M] (lines 156-172)
- Field order enforced (implementer → lean_file → dependencies)

**Enforcement Mechanisms**:
- Pre-commit hook: `.git/hooks/pre-commit` runs validate-plan-metadata.sh on staged plans
- ERROR-level validation: Missing required fields block commits
- WARNING-level validation: Missing optional fields logged but don't block

**Validation Script**: `/home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh` (lines 697-721 in lean-plan-architect.md)

**File References**:
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (lines 1-150: complete field specifications)
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 293-310: metadata field generation)

---

### Finding 4: Hierarchical Agent Architecture Standards Compliance

**Location**: CLAUDE.md section `hierarchical_agent_architecture` (lines 274-295)

**Current /lean-plan Compliance with Example 8 Pattern**:

✅ **Research Coordinator Integration** (fully compliant):
- Uses research-coordinator for parallel multi-topic Lean research (Block 1e-exec in lean-plan.md)
- Metadata-only passing: 330 tokens vs 7,500 tokens (95% context reduction)
- Hard barrier pattern: pre-calculated report paths, artifact validation (Block 1f)
- Partial success mode: ≥50% threshold for report validation (lines 1026-1056 in hierarchical-agents-examples.md)

✅ **Context Efficiency** (documented in Example 8):
- Research phase: 95% reduction (7,500 → 330 tokens)
- Parallel execution: 40-60% time savings for multi-topic research
- Iteration capacity: 10+ iterations possible (vs 3-4 before optimization)

✅ **Integration Points** (as specified):
- `/lean-plan`: Integrated (research-coordinator for parallel multi-topic Lean research) ✓
- `/lean-implement`: Integrated (implementer-coordinator for wave-based orchestration) ✓

**Alignment with Hierarchical Agent Principles** (from hierarchical-agents-overview.md):

1. **Hierarchical Supervision** ✓
   ```
   /lean-plan Command
     └─ research-coordinator (Supervisor)
          ├─ research-specialist 1 (Mathlib Theorems)
          ├─ research-specialist 2 (Proof Strategies)
          └─ research-specialist 3 (Project Structure)
   ```

2. **Behavioral Injection** ✓
   - research-coordinator receives behavior via runtime injection (Task prompt references .claude/agents/research-coordinator.md)
   - No hardcoded instructions in /lean-plan command

3. **Metadata-Only Context Passing** ✓
   - Coordinator returns aggregated metadata (110 tokens per report)
   - Primary agent receives summary only, uses Read tool for full reports (delegated read pattern)

4. **Single Source of Truth** ✓
   - research-coordinator behavioral guidelines: `.claude/agents/research-coordinator.md` (single location)
   - lean-plan-architect behavioral guidelines: `.claude/agents/lean-plan-architect.md` (single location)
   - No duplication in command files

**File References**:
- `/home/benjamin/.config/CLAUDE.md` (lines 274-295: hierarchical agent architecture section)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (lines 1-177: core principles)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 895-1185: Example 8 implementation)

---

### Finding 5: Code Standards and Command Authoring Compliance

**Location**: CLAUDE.md sections `code_standards` (lines 67-94) and `.claude/docs/reference/standards/command-authoring.md`

**Three-Tier Sourcing Pattern Compliance**:

✅ **/lean-plan Command** (lines 187-200 in lean-plan.md):
```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" || exit 1

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true
```

**Validation**: ✅ Linter check-library-sourcing.sh validates sourcing pattern (ERROR-level enforcement)

**Task Tool Invocation Pattern Compliance**:

✅ **/lean-plan Command** (lines 994-1045):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel Lean research across ${TOPIC_COUNT} topics"
  prompt: "..."
}
```

**Validation**: ✅ Follows imperative directive pattern ("**EXECUTE NOW**: USE the Task tool...")

**Error Logging Integration**:

✅ **/lean-plan Command** (lines 203-227):
```bash
# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/lean-plan"
WORKFLOW_ID="lean_plan_$(date +%s)"
USER_ARGS="$*"

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Log validation errors
if [ -z "$FEATURE_DESCRIPTION" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Feature description is empty" "argument_validation" "{}"
  exit 1
fi
```

**Validation**: ✅ 80%+ error exit points logged (meets coverage threshold)

**Path Validation Compliance**:

✅ **/lean-plan Command** (lines 161-182):
```bash
# Detect PROJECT_DIR
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
```

**Validation**: ✅ Handles PROJECT_DIR under HOME correctly (no false positives)

**File References**:
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (lines 1-200: complete sourcing patterns)
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (lines 1-200: Task invocation patterns)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 187-227: implementation)

---

### Finding 6: Output Formatting and Non-Interactive Testing Standards

**Location**: CLAUDE.md sections `output_formatting` (lines 178-190) and `non_interactive_testing` (lines 96-123)

**Output Formatting Compliance**:

✅ **Library Sourcing Suppression** (lean-plan.md lines 187-200):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```
- Suppresses stdout with `2>/dev/null` while preserving error handling

✅ **Block Consolidation** (lean-plan.md structure):
- Block 1a: Initial Setup (argument capture, library sourcing, state initialization)
- Block 1b: Topic Path Pre-Calculation
- Block 1b-exec: Topic Naming Agent Invocation
- Block 1c: Topic Name Validation
- Block 1d: Research Path Pre-Calculation
- Block 1d-topics: Research Topics Classification
- Block 1e-exec: Research Coordinator Invocation
- Block 1f: Research Validation
- Block 2: Plan Architect Invocation
- **Total**: 9 blocks (target: 2-3 bash blocks per phase achieved via Setup/Execute/Cleanup pattern)

✅ **Checkpoint Format** (lean-plan.md throughout):
```bash
echo "[CHECKPOINT] Lean project validated: $LEAN_PROJECT_PATH"
echo "[CHECKPOINT] Research topics: $TOPIC_COUNT topics classified"
echo "[CHECKPOINT] Research verified: ${#REPORT_PATHS[@]} reports created"
```

✅ **Console Summary Format** (lean-plan.md Block 2 completion):
- Uses 4-section format (Summary/Phases/Artifacts/Next Steps)
- No emoji markers in file content (UTF-8 encoding compliance)
- Terminal output may use emoji markers (approved vocabulary)

**Non-Interactive Testing Standards Compliance**:

✅ **lean-plan-architect Test Phase Format** (lean-plan-architect.md lines 1069-1116):
```markdown
**Validation**:
```bash
# Build Lean project and capture exit code
lake build > lake-build.log 2>&1
BUILD_EXIT=$?
test $BUILD_EXIT -eq 0 || { echo "ERROR: Lean compilation failed"; exit 1; }

# Verify no incomplete proofs
SORRY_COUNT=$(grep -c "sorry" [LEAN_FILE_PATH] || echo 0)
test $SORRY_COUNT -eq 0 || { echo "ERROR: Found $SORRY_COUNT incomplete proofs"; exit 1; }

# Verify theorem count
THEOREM_COUNT=$(grep -c "^theorem " [LEAN_FILE_PATH] || echo 0)
[ "$THEOREM_COUNT" -eq [EXPECTED_COUNT] ] || { echo "ERROR: Expected [EXPECTED_COUNT] theorems"; exit 1; }
```
```

**Required Automation Metadata**:
- automation_type: "automated" (Lean compiler validation is inherently automated) ✓
- validation_method: "programmatic" (compiler exit codes and sorry counting) ✓
- skip_allowed: false (proof validation non-optional) ✓
- artifact_outputs: ["lake-build.log", "proof-verification.txt", "sorry-count.txt"] ✓

**Anti-Pattern Prohibition**: ✅ No interactive patterns used ("manually verify", "skip for now", "optional testing")

**Enforcement**: validate-non-interactive-tests.sh checks plans for automation metadata (ERROR-level)

**File References**:
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` (referenced in CLAUDE.md lines 178-190)
- `/home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md` (referenced in CLAUDE.md lines 96-123)
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 1069-1116: Lean compiler validation pattern)

---

### Finding 7: Infrastructure Integration Assessment

**Location**: Various .claude/lib/ and .claude/scripts/ directories

**Existing Infrastructure Components Used by /lean-plan**:

✅ **State Persistence** (state-persistence.sh):
- `append_workflow_state`: Persists variables across bash blocks (lines 808-825 in lean-plan.md use bulk variant)
- `load_workflow_state`: Restores variables in subsequent blocks
- `validate_state_restoration`: Validates critical variables restored (Tier 1 validation-utils.sh function)

✅ **Workflow State Machine** (workflow-state-machine.sh):
- `sm_initialize`: Sets up state machine with workflow type "research-and-plan" and terminal state "plan"
- `sm_transition`: Validates state transitions (setup → research → plan)
- `sm_get_current_state`: Queries current state for validation

✅ **Error Handling** (error-handling.sh):
- `ensure_error_log_exists`: Creates error log at ~/.cache/claude-code/errors.log
- `setup_bash_error_trap`: Installs trap for unhandled errors
- `log_command_error`: Logs errors with workflow context for /errors and /repair commands
- `_source_with_diagnostics`: Wrapper for library sourcing with diagnostic output

✅ **Validation Utils** (validation-utils.sh):
- `validate_agent_artifact`: Validates agent outputs exist and meet minimum size (500 bytes for research reports)
- `validate_state_restoration`: Checks critical variables restored from state file
- `validate_path_consistency`: Handles PROJECT_DIR under HOME correctly

✅ **Library Version Check** (library-version-check.sh):
- `check_library_version`: Validates required library versions (workflow-state-machine.sh >=2.0.0, state-persistence.sh >=1.5.0)

✅ **Summary Formatting** (summary-formatting.sh, Tier 2):
- Console summary generation with 4-section format
- Checkpoint marker formatting

**Infrastructure Components NOT Used (Correctly)**:

❌ **dependency-analyzer.sh**: NOT used by /lean-plan (correct separation - this is /lean-implement infrastructure)
- Purpose: Parses plan dependencies for wave extraction during implementation
- Usage: /lean-implement reads plan's `dependencies: []` fields to construct waves
- /lean-plan generates plans with correct dependency format; /lean-implement consumes them

✅ **topic-naming-agent.md**: Used for semantic topic directory name generation
- Invoked in Block 1b-exec of lean-plan.md
- Haiku LLM agent analyzes feature description and generates directory name (e.g., "063_lean_plan_coordinator_delegation")
- Hard barrier pattern: path pre-calculated before agent invocation

**Infrastructure Redundancy Assessment**: ✅ No redundancy detected
- Each infrastructure component has single responsibility
- No overlapping functionality between components
- Clear separation between planning infrastructure (/lean-plan) and execution infrastructure (/lean-implement)

**File References**:
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh`
- `/home/benjamin/.config/.claude/lib/core/library-version-check.sh`
- `/home/benjamin/.config/.claude/lib/core/summary-formatting.sh`
- `/home/benjamin/.config/.claude/agents/topic-naming-agent.md`

---

### Finding 8: Wave Structure Preview Generation Opportunity

**Location**: lean-plan-architect.md lines 540-677

**Current Documentation** (STEP 2.6 in lean-plan-architect.md):
- Agent instructed to calculate wave structure from phase dependencies (Kahn's algorithm)
- Display wave structure preview in console output
- Append wave structure as HTML comment in plan file
- Return wave count in PLAN_CREATED signal

**Implementation Status**: ✅ Documented but not enforced with validation checkpoint

**Enhancement Opportunity**:
Add STEP 2.7 validation checkpoint to ensure wave structure preview was generated:
```bash
# Validate wave structure preview generated
if ! grep -q "WAVE STRUCTURE (Generated by lean-plan-architect)" "$PLAN_PATH"; then
  echo "WARNING: Wave structure preview not generated" >&2
  echo "This is informational - planning agent should include wave preview"
fi
```

**Wave Structure Format** (lines 586-614):
```
═══════════════════════════════════════════════════════════
                   WAVE STRUCTURE PREVIEW
═══════════════════════════════════════════════════════════

Wave 1 (Parallel): Phases 1, 2, 3
  - 3 phases executing concurrently
  - Wave duration: 2.0 hours (longest phase)

Wave 2 (Parallel): Phases 4, 5
  - 2 phases executing concurrently
  - Wave duration: 3.0 hours (longest phase)

Wave 3 (Sequential): Phase 6
  - 1 phase (no parallelization)
  - Wave duration: 1.5 hours

─────────────────────────────────────────────────────────────
PARALLELIZATION METRICS
─────────────────────────────────────────────────────────────
Sequential Execution Time: 12.0 hours (sum of all phases)
Parallel Execution Time:    6.5 hours (wave-based)
Time Savings:              45.8% (5.5 hours saved)

Parallelization Efficiency: Good (3 concurrent phases in Wave 1)
═══════════════════════════════════════════════════════════
```

**Return Signal Enhancement** (lines 669-674):
```
PLAN_CREATED: /absolute/path/to/plan.md
WAVES: 3
PARALLELIZATION: 45.8%
PHASES: 6
```

**Benefit**: User visibility into parallelization opportunities before implementation phase

**File Reference**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 540-677)

---

## Recommendations

### Recommendation 1: Use Existing research-coordinator (No New Agent)

**Rationale**: research-coordinator.md already supports Mode 2 (pre-decomposed topics) delegation pattern required by /lean-plan. Creating a lean-specific coordinator variant would introduce unnecessary code duplication.

**Implementation**: None required - /lean-plan already uses research-coordinator correctly (as of 2025-12-08 integration).

**File Impact**: None (no new files)

---

### Recommendation 2: Add Metadata Completeness to lean-plan-architect

**Rationale**: Align with Plan Metadata Standard by enforcing Complexity Score calculation, Structure Level insertion, and Estimated Phases tracking.

**Implementation**:

**STEP 1 Enhancement** (after theorem dependency analysis):
```markdown
**Complexity Score Calculation** (MANDATORY - Calculate During STEP 1):

Calculate complexity score based on formalization characteristics:
```
Base (formalization type):
- New formalization: 15
- Extend existing: 10
- Refactor proofs: 7

+ (Theorems × 3)
+ (Files × 2)
+ (Complex Proofs × 5)
```

**Example**: 8 theorems, 1 file, 2 complex proofs → 15 + (8×3) + (1×2) + (2×5) = 51.0

Store result for STEP 2 metadata insertion.

**CHECKPOINT**: Complexity score calculated: {score}.
```

**STEP 2 Enhancement** (metadata section):
```markdown
**Metadata Fields** (add after Estimated Hours):
```markdown
- **Complexity Score**: {score} (calculated in STEP 1)
- **Structure Level**: 0 (Lean plans always single-file)
- **Estimated Phases**: {N} (from STEP 1 theorem analysis)
```
```

**STEP 3 Enhancement** (verification):
```bash
# Validate metadata completeness
grep -q "Complexity Score:" "$PLAN_PATH" || {
  echo "ERROR: Complexity Score missing from plan metadata" >&2
  exit 1
}
grep -q "Structure Level: 0" "$PLAN_PATH" || {
  echo "ERROR: Structure Level missing from plan metadata" >&2
  exit 1
}
grep -q "Estimated Phases:" "$PLAN_PATH" || {
  echo "ERROR: Estimated Phases missing from plan metadata" >&2
  exit 1
}
```

**File Impact**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 220-237 expansion, lines 293-310 additions, lines 680-810 validation additions)

---

### Recommendation 3: Add Wave Structure Preview Validation

**Rationale**: Ensure lean-plan-architect generates wave structure preview for user visibility into parallelization opportunities.

**Implementation**:

**STEP 2.7 Addition** (after plan file creation):
```markdown
### STEP 2.7 (RECOMMENDED) - Validate Wave Structure Preview

**Objective**: Verify wave structure preview was generated and appended to plan.

**Actions**:

```bash
# Check for wave structure comment in plan file
if ! grep -q "WAVE STRUCTURE (Generated by lean-plan-architect)" "$PLAN_PATH"; then
  echo "WARNING: Wave structure preview not found in plan file" >&2
  echo "Agent should have generated wave preview per STEP 2.6 instructions" >&2
  # Non-fatal warning - plan is still valid
fi

# Display wave metrics from plan
WAVE_COUNT=$(grep "^Wave [0-9]" "$PLAN_PATH" | wc -l)
if [ "$WAVE_COUNT" -gt 0 ]; then
  echo "[CHECKPOINT] Wave structure generated: $WAVE_COUNT waves"
else
  echo "[CHECKPOINT] Wave structure not generated (single-phase plan?)"
fi
```

**CHECKPOINT**: Wave structure validation complete.
```

**File Impact**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (add STEP 2.7 after line 677)

---

### Recommendation 4: Document Research Coordinator Integration in Lean Plan Command Guide

**Rationale**: Update user-facing documentation to reflect research-coordinator integration and context efficiency benefits.

**Implementation**:

Add section to `.claude/docs/guides/commands/lean-plan-command-guide.md`:

```markdown
## Research Coordinator Integration

The /lean-plan command uses hierarchical agent architecture with research-coordinator delegation for parallel multi-topic Lean research.

**Architecture**:
```
/lean-plan Command
  └─ research-coordinator (Supervisor)
       ├─ research-specialist 1 (Mathlib Theorems)
       ├─ research-specialist 2 (Proof Strategies)
       ├─ research-specialist 3 (Project Structure)
       └─ research-specialist 4 (Style Guide)
```

**Context Efficiency**:
- Research phase: 95% reduction (7,500 tokens → 330 tokens)
- Metadata-only passing: 110 tokens per report
- Parallel execution: 40-60% time savings

**Topic Count**:
- Complexity 1-2: 2 topics (Mathlib + Proofs)
- Complexity 3: 3 topics (Mathlib + Proofs + Structure)
- Complexity 4: 4 topics (Mathlib + Proofs + Structure + Style)

See [Hierarchical Agent Examples](../../concepts/hierarchical-agents-examples.md#example-8-lean-command-coordinator-optimization) for implementation details.
```

**File Impact**: `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md` (add new section after "Command Architecture")

---

### Recommendation 5: No Breaking Changes Required

**Rationale**: All recommendations are additive enhancements. Existing /lean-plan functionality preserved.

**Backward Compatibility Guarantees**:
1. **Command Interface**: No changes to /lean-plan argument syntax
2. **Output Format**: Plan files remain compatible with /lean-implement parser
3. **Agent Contracts**: research-coordinator and lean-plan-architect interfaces unchanged
4. **State Persistence**: Existing state file format preserved
5. **Infrastructure Libraries**: No changes to library function signatures

**Migration Strategy**: None required - enhancements can be deployed incrementally without affecting existing workflows.

---

## Summary of Standards Alignment

**Current Compliance** (8/10 sections):

✅ Fully Compliant:
1. Three-Tier Sourcing Pattern (code_standards)
2. Task Tool Invocation Patterns (command_authoring)
3. Error Logging Integration (error_logging)
4. Path Validation Patterns (command_authoring)
5. Hierarchical Agent Architecture (hierarchical_agent_architecture)
6. Output Formatting Standards (output_formatting)
7. Non-Interactive Testing Standards (non_interactive_testing)
8. Infrastructure Integration (directory_organization, development_workflow)

⚠️ Partial Compliance (enhancements recommended):
9. Plan Metadata Standard (plan_metadata_standard) - Missing Complexity Score, Structure Level, Estimated Phases
10. Wave Structure Preview (hierarchical_agent_architecture) - Documented but not validated

**Post-Enhancement Compliance**: 10/10 sections (full alignment)

---

## Conclusion

The /lean-plan command demonstrates strong standards compliance and efficient infrastructure integration. No new coordinator agent is required - the existing research-coordinator fully supports the needed delegation pattern via Mode 2 invocation. Only three minor conformance updates are needed in lean-plan-architect to achieve 100% Plan Metadata Standard compliance:

1. Mandatory Complexity Score calculation and insertion
2. Explicit Structure Level: 0 enforcement for all Lean plans
3. Estimated Phases tracking in metadata

All proposed enhancements are additive with no breaking changes, preserving existing functionality while improving standards alignment and user visibility into parallelization opportunities.

**File References Summary**:
- `/home/benjamin/.config/CLAUDE.md` (lines 67-295: standards sections)
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 1-422: complete agent specification)
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 1-1116: complete agent specification)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1-1100: complete command specification)
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (lines 1-172: complete standard)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (lines 1-177: architecture principles)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 545-1185: research-coordinator pattern, Example 7-8)
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (state persistence infrastructure)
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` (workflow orchestration infrastructure)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (error logging infrastructure)
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh` (validation infrastructure)

---

**Research Completion Signal**:

REPORT_CREATED: /home/benjamin/.config/.claude/specs/004_lean_plan_context_coordinator/reports/004-standards-compliant-infrastructure.md

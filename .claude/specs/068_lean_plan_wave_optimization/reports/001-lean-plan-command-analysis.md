# Research Report: Current /lean-plan Command Architecture and Behavior Analysis

**Date**: 2025-12-09
**Topic**: Current /lean-plan Command Architecture and Behavior Analysis
**Status**: COMPLETE

## Executive Summary

The `/lean-plan` command is a research-and-plan workflow orchestrator that creates Lean-specific implementation plans with theorem-level granularity, Mathlib research integration, and wave-based dependency structures. This report analyzes its architecture to identify opportunities for optimization in preparing plans for parallel wave execution via `/lean-implement`.

**Key Findings**:
1. **Command uses dual-coordinator architecture**: research-coordinator (parallel Mathlib research) + lean-plan-architect (plan generation)
2. **Wave indicators are implicit**: Plans use `dependencies: []` metadata; waves constructed dynamically by dependency-analyzer.sh
3. **Tight integration with /lean-implement**: Plan format includes Phase Routing Summary, per-phase file targeting, and automation metadata
4. **Hard Barrier Pattern throughout**: Pre-calculated paths, artifact validation, metadata-only passing (95% context reduction)
5. **Standards integration**: Plan Metadata Standard validation, non-interactive testing standards, Lean compiler automation

**Optimization Opportunities**:
1. Enhance Phase Routing Summary with wave hints (optional parallelism metadata)
2. Add theorem dependency hints in plan output (complementing phase dependencies)
3. Improve plan metadata for lean-coordinator's wave construction (estimated durations, complexity scores)
4. Consider pre-computing wave structure in lean-plan-architect (trade planning time for execution time)

## Research Findings

### 1. Command Structure

**File**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (84,778 bytes, 2,142 lines)

**Architecture**: Multi-block orchestrator with hard barrier pattern enforcement

**Block Sequence**:
1. **Block 1a**: Argument capture, state initialization, Lean project detection, library sourcing
2. **Block 1b**: Topic name pre-calculation (hard barrier contract)
3. **Block 1b-exec**: Topic-naming-agent delegation (Task tool)
4. **Block 1c**: Topic name validation (hard barrier)
5. **Block 1d**: Topic path initialization, research directory setup
6. **Block 1d-topics**: Research topics classification (complexity-based)
7. **Block 1e-exec**: research-coordinator delegation (parallel research)
8. **Block 1e-validate**: Coordinator output signal validation
9. **Block 1f**: Research reports hard barrier validation
10. **Block 2a**: Research verification, state transition (RESEARCH → PLAN)
11. **Block 2b-exec**: lean-plan-architect delegation (plan creation)
12. **Block 2c**: Plan hard barrier validation

**Dependent Agents** (frontmatter):
- `topic-naming-agent`: Generates semantic directory names from prompts
- `research-coordinator`: Coordinates parallel Mathlib research across 2-4 topics
- `lean-plan-architect`: Creates theorem-level implementation plans with wave dependencies

**Library Requirements**:
- `workflow-state-machine.sh: ">=2.0.0"`
- `state-persistence.sh: ">=1.5.0"`

### 2. Input Handling

**Argument Syntax**:
```bash
/lean-plan "<feature-description>" [--complexity 1-4] [--project <path>]
# OR
/lean-plan --file <prompt-file> [--complexity 1-4] [--project <path>]
```

**Input Validation** (Block 1a, lines 35-159):
1. **Feature description capture**: Via temp file pattern (preprocessing-safe)
2. **Meta-instruction detection**: Warns if user provides "use X to create Y" patterns
3. **Complexity validation**: Ensures 1-4 range, defaults to 3
4. **File flag handling**: Reads long prompts from external files, archives in `specs/NNN_topic/prompts/`
5. **Project flag parsing**: Absolute path conversion, lakefile.toml validation

**Lean Project Detection** (lines 131-159):
- Auto-detects Lean project via upward search for `lakefile.toml` or `lakefile.lean`
- Falls back to `--project` flag if not in Lean directory
- Validates project structure before proceeding

**Example Input Processing**:
```bash
# Simple invocation
/lean-plan "formalize group homomorphism properties"
→ Feature: "formalize group homomorphism properties"
→ Complexity: 3 (default)
→ Project: Auto-detected via lakefile.toml search

# Complex invocation with file
/lean-plan --file formalization-spec.md --complexity 4 --project ~/ProofChecker
→ Feature: Read from formalization-spec.md
→ Complexity: 4 (exhaustive research)
→ Project: ~/ProofChecker (explicit)
```

### 3. Output Generation

**Primary Artifacts**:
1. **Research Reports** (4 topics): `specs/NNN_topic/reports/001-mathlib-theorems.md`, `002-proof-strategies.md`, `003-project-structure.md`, `004-style-guide.md`
2. **Implementation Plan**: `specs/NNN_topic/plans/001-topic-plan.md`
3. **Archived Prompt** (if `--file` used): `specs/NNN_topic/prompts/prompt.md`

**Plan Format** (lean-plan-architect.md, lines 187-360):

**Metadata Section**:
```markdown
## Metadata
- **Date**: 2025-12-09
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

**Phase Routing Summary** (lean-plan-architect.md, lines 239-258):
```markdown
## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
| 1 | lean | lean-implementer |
| 2 | software | implementer-coordinator |
| 3 | lean | lean-implementer |
```

**Phase Format** (lean-plan-architect.md, lines 532-605):
```markdown
### Phase 1: Basic Commutativity Properties [NOT STARTED]
implementer: lean
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

**Testing**:
```bash
lake build
grep -c "sorry" ProofChecker/Basics.lean
```

**Expected Duration**: 1 hour

---
```

**Critical Format Requirements** (lean-plan-architect.md, lines 302-352):
- Field order MUST be: `implementer:` → `lean_file:` → `dependencies:`
- Phase headings MUST use level 3: `### Phase N:` (not `##`)
- All phases MUST include `[NOT STARTED]` marker for new plans
- Dependencies MUST use array syntax: `dependencies: []` (not `**Dependencies**: None`)

### 4. Mathlib Research Integration

**Research Coordination** (Block 1e-exec, lines 992-1045):

**Complexity-Based Topic Count** (Block 1d-topics, lines 897-902):
```bash
case "$RESEARCH_COMPLEXITY" in
  1|2) TOPIC_COUNT=2 ;;
  3)   TOPIC_COUNT=3 ;;
  4)   TOPIC_COUNT=4 ;;
esac
```

**Standard Lean Topics** (lines 905-911):
1. Mathlib Theorems (theorem discovery, type signatures)
2. Proof Strategies (tactic sequences, proof patterns)
3. Project Structure (module organization, naming conventions)
4. Style Guide (LEAN_STYLE_GUIDE.md extraction if exists)

**research-coordinator Delegation Contract** (Block 1e-exec, lines 1000-1044):
- **Mode 2: Pre-Decomposed Topics** - Orchestrator calculates report paths, passes to coordinator
- **Lean-Specific Context**: LEAN_PROJECT_PATH, Mathlib focus, lakefile.toml location
- **Parallel Execution**: Each research-specialist invoked in parallel via Task tool
- **Metadata-Only Return**: Coordinator returns aggregated metadata (title, findings_count, recommendations_count) - 95% context reduction
- **Hard Barrier Validation**: Block 1f validates all reports exist and meet minimum size (500 bytes)

**Research Report Consumption** (Block 2b-exec, lines 1904-1920):
- **Metadata-Only Passing**: lean-plan-architect receives FORMATTED_METADATA (not full reports)
- **Read Tool Access**: Agent can read full reports when needed for detailed planning
- **Context Optimization**: Reduces prompt size from ~7,500 tokens to ~330 tokens

### 5. Integration with /lean-implement

**Plan Metadata for Wave Execution**:

**Phase Routing Summary** (lean-plan-guide.md, lines 444-465):
- `/lean-implement` reads this table to route phases upfront
- Prevents phase-by-phase classification overhead
- Enables early split between lean-coordinator and implementer-coordinator

**Phase Dependencies Syntax** (lean-plan-guide.md, lines 516-540):
```markdown
dependencies: []         # Wave 1 (no dependencies)
dependencies: [1]        # Wave 2 (depends on Phase 1)
dependencies: [1, 2]     # Wave 3 (depends on Phases 1 and 2)
```

**Wave Construction Algorithm** (specs/065/reports/003-lean-plan-wave-indicators.md, lines 96-147):
- Waves are **INFERRED** from dependencies (not explicitly marked)
- dependency-analyzer.sh performs topological sort (Kahn's algorithm)
- lean-coordinator consumes wave structure in Block 2 (STEP 2)
- Example wave display:
```
Wave 1: Independent Theorems (3 phases, PARALLEL)
├─ Phase 1: theorem_add_comm
├─ Phase 2: theorem_mul_assoc
└─ Phase 3: theorem_zero_add

Wave 2: Dependent Theorems (3 phases, PARALLEL)
├─ Phase 4: theorem_ring_properties
├─ Phase 5: theorem_field_division
└─ Phase 6: theorem_complete_ring
```

**Per-Phase File Targeting** (lean-plan-architect.md, lines 123-139):
- Tier 1 Discovery: `lean_file: /absolute/path` immediately after phase heading
- Tier 2 Fallback: `**Lean File**` in metadata section
- Enables multi-file theorem proving workflows
- lean-coordinator routes phases to correct files for batch processing

**Theorem Specifications** (lean-plan-architect.md, lines 274-299):
- **Goal**: Lean 4 type signature (e.g., `∀ a b : Nat, a + b = b + a`)
- **Strategy**: Specific tactics and Mathlib theorems to apply
- **Complexity**: Simple/Medium/Complex for effort estimation
- **Prerequisites**: Other theorems needed (theorem-level dependencies within phase)

**Automation Metadata** (lean-plan-architect.md, lines 748-791):
- `automation_type: "automated"` (Lean compiler validation)
- `validation_method: "programmatic"` (exit codes, sorry counting)
- `skip_allowed: false` (proof validation non-optional)
- `artifact_outputs: ["lake-build.log", "proof-verification.txt", "sorry-count.txt"]`

### 6. Design Patterns and Constraints

**Hard Barrier Pattern** (ubiquitous):
1. **Pre-Calculate Paths**: Orchestrator calculates output paths BEFORE agent delegation
2. **Explicit Contracts**: Paths passed as literal text in agent prompts
3. **Post-Validation**: File existence and size validated AFTER agent returns
4. **Fallback Naming**: Graceful degradation if agent fails (timestamp + sanitized prompt)

**Examples**:
- Topic name file: Block 1b pre-calculates, Block 1b-exec delegates, Block 1c validates
- Research reports: Block 1d-topics pre-calculates array, Block 1e-exec delegates, Block 1f validates
- Plan file: Block 2a pre-calculates, Block 2b-exec delegates, Block 2c validates

**Metadata-Only Context Passing** (research-coordinator pattern):
- Research reports NOT passed in full to lean-plan-architect
- Only metadata passed (title, findings count, recommendations count)
- Agent has Read tool access for full content when needed
- 95% context reduction: 330 tokens vs 7,500 tokens

**Three-Tier Library Sourcing** (Block 1a, lines 186-214):
```bash
# Tier 1: Critical Foundation (fail-fast required)
source error-handling.sh || exit 1
_source_with_diagnostics state-persistence.sh || exit 1
_source_with_diagnostics workflow-state-machine.sh || exit 1

# Tier 2: Workflow Support (graceful degradation)
source unified-location-detection.sh 2>/dev/null || true
source workflow-initialization.sh 2>/dev/null || true

# Tier 3: Helper utilities (graceful degradation)
source validation-utils.sh 2>/dev/null || { echo "ERROR..."; exit 1; }
```

**State Persistence Patterns**:
- Bulk append for efficiency: Block 1d reduces 14 writes to 1 write (lines 809-825)
- Cross-block state restoration: Each block loads STATE_FILE via WORKFLOW_ID
- Defensive variable initialization: Set defaults before state file source (lines 657-676)

**Error Logging Integration**:
- `ensure_error_log_exists` in Block 1a (line 223)
- `setup_bash_error_trap` for automatic error capture (line 227)
- `log_command_error` for structured error logging throughout
- `_flush_early_errors` to transfer pre-trap errors to errors.jsonl (line 248)

**Standards Integration** (Block 2a, lines 1777-1841):
- `format_standards_for_prompt()` extracts CLAUDE.md sections
- `extract_testing_standards()` injects non-interactive testing patterns
- Lean style guide extraction from `LEAN_PROJECT_PATH/LEAN_STYLE_GUIDE.md`
- Plan Metadata Standard validation via `validate-plan-metadata.sh` (lean-plan-architect.md, lines 380-401)

**Constraints and Limitations**:
1. **Structure Level Always 0**: Lean plans do NOT support Level 1 expansion (theorem-level granularity only)
2. **Single lakefile.toml**: Auto-detection assumes one Lean project per invocation
3. **Sequential Research Then Plan**: research-coordinator must complete before lean-plan-architect starts
4. **No Plan Revision During Creation**: Plan created once; use `/revise` for changes
5. **4-Topic Research Maximum**: Complexity 4 caps at 4 research topics

## Recommendations

### 1. Enhance Wave-Preparedness in Plan Output

**Current State**: Plans provide `dependencies: []` metadata only; waves constructed dynamically by dependency-analyzer.sh

**Opportunity**: Pre-compute wave structure in lean-plan-architect and include as metadata

**Benefit**: lean-coordinator can skip dependency analysis overhead (2-3 tool calls saved)

**Implementation**:
```markdown
## Metadata
- **Estimated Waves**: 3
- **Parallel Phases**: 6 out of 10
- **Sequential Time**: 12 hours
- **Parallel Time**: 6 hours
- **Time Savings**: 50%
```

**Trade-off**: Increases planning time slightly, reduces execution time significantly (especially for large plans)

### 2. Add Theorem Dependency Hints

**Current State**: Phase dependencies only; theorem prerequisites listed textually

**Opportunity**: Formalize theorem dependencies for intra-phase parallelism

**Benefit**: lean-implementer can prove independent theorems within phase in parallel

**Implementation**:
```markdown
**Theorems**:
- [ ] `theorem_add_comm`: Prove addition commutativity
  - Goal: `∀ a b : Nat, a + b = b + a`
  - Strategy: Use `Nat.add_comm` from Mathlib
  - Complexity: Simple
  - Depends On: [] # No theorem dependencies
  - Estimated: 0.5 hours

- [ ] `theorem_distributivity`: Prove distributivity
  - Goal: `∀ a b c : Nat, a * (b + c) = a * b + a * c`
  - Strategy: Apply ring tactic
  - Complexity: Medium
  - Depends On: [theorem_add_comm, theorem_mul_comm] # Intra-phase dependencies
  - Estimated: 2 hours
```

**Parsing**: Extend dependency-analyzer.sh to handle theorem-level dependencies

### 3. Improve Duration Estimates for Wave Scheduling

**Current State**: Per-theorem estimates exist, but wave-level aggregates not pre-calculated

**Opportunity**: Provide wave-level duration estimates for better scheduling

**Implementation** (in Phase Routing Summary):
```markdown
### Phase Routing Summary
| Phase | Type | Implementer | Duration | Wave | Parallel Group |
|-------|------|-------------|----------|------|----------------|
| 1 | lean | lean-implementer | 1h | 1 | - |
| 2 | lean | lean-implementer | 2h | 2 | A |
| 3 | lean | lean-implementer | 2h | 2 | A |
| 4 | lean | lean-implementer | 4h | 3 | - |
```

**Benefit**: lean-coordinator can prioritize longer waves first, balance parallel workloads

### 4. Consider lean-plan-architect Invocation of dependency-analyzer.sh

**Current State**: lean-plan-architect generates dependency metadata; lean-coordinator runs dependency-analyzer.sh

**Opportunity**: lean-plan-architect runs dependency-analyzer.sh AFTER plan creation, appends wave structure to plan

**Benefit**:
- Validate dependency graph during planning (catch circular dependencies early)
- Pre-compute wave structure for execution
- Provide user feedback on parallelization opportunities

**Implementation**:
```markdown
## Metadata
- **Dependency Graph**: Acyclic (validated)
- **Wave Structure**:
  - Wave 1: 3 phases (parallel)
  - Wave 2: 4 phases (parallel)
  - Wave 3: 2 phases (parallel)
```

**Trade-off**: Requires lean-plan-architect to have Bash tool access (currently Read, Write, Edit, Grep, Glob, WebSearch only)

### 5. Standardize Complexity Score Calculation

**Current State**: lean-plan-architect.md documents formula (lines 218-230), but not enforced

**Opportunity**: Create `calculate_lean_complexity_score.sh` utility for consistent scoring

**Formula**:
```bash
Base (formalization type):
- New formalization: 15
- Extend existing: 10
- Refactor proofs: 7

+ (Theorems × 3)
+ (Files × 2)
+ (Complex Proofs × 5)
```

**Benefit**: Consistent complexity scores enable better resource estimation and scheduling

### 6. Add Mathlib Version Metadata

**Current State**: Plans don't record Mathlib version used during research

**Opportunity**: Extract Mathlib version from lakefile.toml and include in plan metadata

**Implementation**:
```markdown
## Metadata
- **Mathlib Version**: v4.5.0
- **Lean Version**: v4.5.0
```

**Benefit**: Reproducibility, compatibility checking, version-specific theorem references

## References

1. `/lean-plan` Command: `/home/benjamin/.config/.claude/commands/lean-plan.md`
2. `lean-plan-architect` Agent: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
3. `/lean-implement` Command: `/home/benjamin/.config/.claude/commands/lean-implement.md`
4. Lean Plan Command Guide: `/home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md`
5. Plan Metadata Standard: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`
6. Wave Indicators Research: `/home/benjamin/.config/.claude/specs/065_lean_coordinator_wave_optimization/reports/003-lean-plan-wave-indicators.md`
7. Hierarchical Agents Examples: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Example 8: Lean coordinator optimization)

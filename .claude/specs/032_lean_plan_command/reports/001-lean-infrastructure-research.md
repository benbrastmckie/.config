# Lean Infrastructure Research Report

**Date**: 2025-12-03
**Research Complexity**: 3
**Research Topic**: Creating a /lean:plan command for Lean theorem proving implementation plans
**Workflow Type**: research-and-plan

---

## Executive Summary

This report documents the current Lean infrastructure and proposes a design for a `/lean:plan` command that creates structured implementation plans for Lean theorem proving projects. After analyzing the existing `/lean` command, lean-lsp-mcp integration, and the ProofChecker Lean project, **three key findings** emerge:

1. **The `/lean` command already exists** and provides comprehensive theorem proving capabilities via the lean-implementer and lean-coordinator agents
2. **Plan-based Lean workflows are fully operational** with 3-tier Lean file discovery, wave-based parallel proving, and real-time progress tracking
3. **A `/lean:plan` command would follow the `/plan` pattern** to create Lean-specific implementation plans with theorem dependencies, proof strategies, and Mathlib research

The analysis reveals that `/lean:plan` should integrate with the existing `/lean` execution infrastructure while adding Lean-specific planning capabilities for complex formalization projects.

---

## Research Findings

### 1. Current State: /lean Command Infrastructure

#### Command Architecture

The `/lean` command (`.claude/commands/lean.md`) provides a complete theorem proving workflow:

**Command Syntax**:
```bash
/lean [lean-file | plan-file] [--prove-all | --verify] [--max-attempts=N] [--max-iterations=N]
```

**Execution Modes**:

1. **File-Based Mode**: Direct Lean file proving
   - Identifies all `sorry` markers in file
   - Proves theorems sequentially
   - No plan file required
   - Usage: `/lean Test.lean --prove-all`

2. **Plan-Based Mode**: Structured multi-theorem proving
   - Executes phases from plan file
   - Wave-based parallel execution with dependency analysis
   - Real-time progress tracking via plan markers
   - Usage: `/lean plan.md --prove-all`

**Key Workflow Blocks**:

```
Block 1a: Setup & State Initialization
├─ Argument capture and validation
├─ Project directory detection
├─ Library sourcing (error-handling, state-persistence, workflow-state-machine)
├─ Error logging initialization
└─ Mode detection (file-based vs plan-based)

Block 1b: Coordinator/Implementer Invocation [HARD BARRIER]
├─ Plan-Based: Invokes lean-coordinator for wave orchestration
└─ File-Based: Invokes lean-implementer for sequential proving

Block 1c: Verification & Iteration Decision
├─ Validate summary creation (mandatory artifact)
├─ Parse work_remaining and context_exhausted signals
├─ Stuck detection (2 iterations with no progress)
└─ Iteration continuation decision

Block 1d: Phase Marker Validation and Recovery
├─ Count phases with [COMPLETE] markers
├─ Recover missing markers for completed phases
└─ Update plan metadata status

Block 2: Completion & Summary
├─ Parse final metrics (theorems proven, partial, sorry count)
├─ Display console summary
└─ Emit PROOF_COMPLETE signal
```

**Critical Features**:

1. **3-Tier Lean File Discovery** (Plan-Based Mode):
   - Tier 1: Plan metadata (`**Lean File**: /path/to/file.lean`)
   - Tier 2: Task scanning (extracts `.lean` paths from task descriptions)
   - Tier 3: Directory search (finds first `.lean` file in topic directory)

2. **Iteration Support**: Multi-iteration execution for large proof sessions
   - Context estimation after each iteration
   - Continuation context passing between iterations
   - Checkpoint creation when context threshold (85%) approached
   - Maximum 5 iterations by default

3. **Real-Time Progress Tracking**:
   - Phase markers update during proving: `[NOT STARTED]` → `[IN PROGRESS]` → `[COMPLETE]`
   - Users can monitor via: `watch -n 1 "grep -E '^### Phase.*\[' plan.md"`
   - Graceful degradation if checkbox-utils.sh unavailable

#### Agent Architecture

**lean-implementer Agent** (`.claude/agents/lean-implementer.md`):

**Role**: AI-assisted Lean 4 theorem proving specialist

**Model**: Sonnet 4.5 (complex proof search, tactic generation, deep reasoning)

**Core Capabilities**:

1. **Proof Goal Analysis**
   - Extract proof goals via `lean_goal` MCP tool
   - Identify goal type, hypotheses, target
   - Assess proof complexity

2. **Theorem Discovery**
   - Natural language search: `lean_leansearch` (Mathlib search)
   - Type-based search: `lean_loogle` (signature matching)
   - State-based search: `lean_state_search` (applicable theorems)
   - Local search: `lean_local_search` (ripgrep wrapper, **no rate limits**)

3. **Tactic Exploration**
   - Pattern-based tactic generation (goal type → candidate tactics)
   - Multi-attempt screening: `lean_multi_attempt` (parallel tactic testing)
   - Diagnostic-driven iteration

4. **Proof Completion**
   - Tactic application via Edit tool
   - Compilation verification via `lean_build`
   - Diagnostics checking via `lean_diagnostic_messages`
   - Iteration until no `sorry` markers remain

5. **Progress Tracking** (Plan-Based Mode)
   - Mark phases `[IN PROGRESS]` at start
   - Update to `[COMPLETE]` after successful proof
   - Uses checkbox-utils.sh library

**Rate Limit Management**:
- External search tools share **3 requests/30s limit**
- Budget allocation per implementer (wave-based coordination)
- Prioritize `lean_local_search` (unlimited) before external tools
- Instrumentation via search tool logs

**Input Contract**:
```yaml
lean_file_path: /absolute/path/to/file.lean
topic_path: /absolute/path/to/topic/
artifact_paths:
  summaries: /topic/summaries/
  debug: /topic/debug/
max_attempts: 3
plan_path: ""  # Empty string for file-based mode
execution_mode: "file-based" | "plan-based"
theorem_tasks: []  # Empty array = all sorry markers, non-empty = specific theorems
rate_limit_budget: 3
wave_number: 1
phase_number: 0  # 0 for file-based, phase number for plan-based
continuation_context: null  # Path to previous iteration summary
```

**Output Signal**:
```yaml
IMPLEMENTATION_COMPLETE: 1
summary_path: /topic/summaries/001-proof-summary.md
theorems_proven: ["add_comm", "mul_comm"]
theorems_partial: []
tactics_used: ["exact", "rw"]
mathlib_theorems: ["Nat.add_comm", "Nat.mul_comm"]
diagnostics: []
work_remaining: 0
context_exhausted: false
```

**lean-coordinator Agent** (`.claude/agents/lean-coordinator.md`):

**Role**: Wave-based parallel theorem proving orchestrator

**Model**: Haiku 4.5 (deterministic orchestration, mechanical batch coordination)

**Core Responsibilities**:

1. **Dependency Analysis**: Invokes dependency-analyzer utility to build wave structure
2. **Wave Orchestration**: Execute theorem batches wave-by-wave with parallel implementers
3. **Rate Limit Coordination**: Allocate MCP search budget across parallel agents
4. **Progress Monitoring**: Collect proof results in real-time
5. **Failure Handling**: Detect failures, mark theorems, continue independent work
6. **Result Aggregation**: Collect completion reports and metrics
7. **Context Management**: Estimate usage, create checkpoints when needed

**Wave Execution Strategy**:
- Independent theorems execute in parallel within same wave
- Dependent theorems execute in subsequent waves
- 40-60% time savings for typical workflows with 2-4 parallel theorems per wave

**MCP Rate Limit Budget Allocation**:
```bash
# 3 requests per 30 seconds (shared limit across all external search tools)
wave_size=${#theorems_in_wave[@]}
budget_per_implementer=$((3 / wave_size))

# Examples:
# Wave with 1 agent: Budget = 3 requests
# Wave with 2 agents: Budget = 1 request each (total 2, conservative)
# Wave with 3 agents: Budget = 1 request each (total 3, at limit)
# Wave with 4+ agents: Budget = 0-1 requests (rely on lean_local_search)
```

**Synchronization Guarantees**:
- Wave N+1 WILL NOT start until Wave N fully completes
- All implementers in wave MUST report completion
- Dependencies ALWAYS respected (no premature execution)
- `lean_build` verification runs once per wave

**Output Signal**:
```yaml
PROOF_COMPLETE:
  theorem_count: N
  plan_file: /path/to/plan.md
  lean_file: /path/to/file.lean
  topic_path: /path/to/topic
  summary_path: /path/to/summaries/NNN_proof_summary.md
  context_exhausted: true|false
  work_remaining: Phase_4 Phase_5  # Space-separated string, NOT JSON array
  context_usage_percent: 85%
  checkpoint_path: /path/to/checkpoint (if created)
  requires_continuation: true|false
  stuck_detected: true|false
  phases_with_markers: 6
```

**Critical Design Constraint**: `work_remaining` must be **space-separated string** (NOT JSON array) because parent workflow uses `append_workflow_state()` which only accepts scalar values.

#### lean-lsp-mcp Integration

**MCP Server Status**: ✅ OPERATIONAL

**Available Tools** (17 total):

**Core LSP Operations**:
- `lean_file_outline` - File structure analysis
- `lean_file_contents` - File reading
- `lean_diagnostic_messages` - Error/warning retrieval
- `lean_goal` - Proof goal inspection at cursor position
- `lean_term_goal` - Term-level goals
- `lean_hover_info` - Documentation/type information
- `lean_completions` - Code completion suggestions

**Build & Execution**:
- `lean_build` - Project compilation
- `lean_run_code` - Code execution

**Search Tools** (Rate Limited: 3 requests/30s combined):
- `lean_local_search` - Local ripgrep search (**no rate limit, preferred**)
- `lean_leansearch` - Natural language theorem search
- `lean_loogle` - Type/constant/lemma search
- `lean_leanfinder` - Semantic Mathlib search
- `lean_state_search` - Goal-based applicable theorem search
- `lean_hammer_premise` - Premise search based on proof state

**Advanced**:
- `lean_multi_attempt` - Multi-proof screening
- `lean_declaration_file` - Declaration source lookup

**Search Strategy** (Budget-Aware):
1. Always start with `lean_local_search` (no rate limit, unlimited use)
2. If no results and budget available, use `lean_leansearch` (consume 1 budget)
3. If still no results and budget available, use `lean_loogle` (consume 1 budget)
4. If budget exhausted, rely only on local search results
5. Rate limit backoff: If rate limit error detected, fall back to local search

### 2. Analysis of Existing Plan Command Pattern

The `/plan` command (`.claude/commands/plan.md`) provides the template for `/lean:plan`:

**Workflow Type**: `research-and-plan`

**Architecture**:
```
Block 1a: Initial Setup and State Initialization
├─ Capture feature description
├─ Parse complexity flag (default: 3)
├─ Parse --file flag for long prompts
├─ Detect project directory
├─ Source libraries (error-handling, state-persistence, workflow-state-machine)
└─ Initialize workflow state

Block 1b: Topic Name File Path Pre-Calculation
├─ Pre-calculate TOPIC_NAME_FILE path
├─ Validate path is absolute
└─ Persist for Block 1b-exec and Block 1c

Block 1b-exec: Topic Name Generation (Hard Barrier Invocation)
└─ Invoke topic-naming-agent via Task tool

Block 1c: Hard Barrier Validation
└─ Validate topic name file exists at pre-calculated path

Block 1d: Topic Path Initialization
├─ Read topic name from agent output file
├─ Fallback naming if agent failed (timestamp + sanitized prompt)
├─ Create classification JSON for initialize_workflow_paths
├─ Initialize workflow paths with topic name
└─ Archive prompt file (if --file was used)

Block 1d: Research Initiation
└─ Invoke research-specialist agent via Task tool

Block 2: Research Verification and Planning Setup
├─ Verify research artifacts (reports directory, file count, file sizes)
├─ Transition to PLAN state
├─ Prepare plan path
├─ Extract project standards (format_standards_for_prompt)
└─ Invoke plan-architect agent via Task tool

Block 3: Plan Verification and Completion
├─ Verify plan artifacts (file exists, size >= 500 bytes)
├─ Detect Phase 0 (Standards Divergence)
├─ Transition to COMPLETE state
├─ Display console summary
└─ Emit PLAN_CREATED signal
```

**Key Patterns for /lean:plan**:

1. **Topic-Based Directory Structure**: All artifacts in `specs/NNN_topic/`
   - `reports/` - Research reports
   - `plans/` - Implementation plans
   - `summaries/` - Proof summaries (created by /lean)
   - `debug/` - Debug artifacts

2. **Hard Barrier Pattern**: Pre-calculate output paths, pass to agents, validate after return

3. **LLM-Based Topic Naming**: Haiku agent generates semantic directory names (e.g., `032_lean_plan_command`)

4. **Research-Then-Plan Workflow**:
   - Research phase: Investigate Lean libraries, proof patterns, existing formalizations
   - Planning phase: Create structured implementation plan based on research

5. **Standards Extraction**: Extract relevant project standards for plan-architect

6. **Plan Metadata Standard**: Required fields in plan file
   - Date
   - Feature (50-100 chars)
   - Status ([NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED])
   - Estimated Hours (low-high range)
   - Standards File (absolute path to CLAUDE.md)
   - Research Reports (markdown links or "none")

7. **Phase Format**: Progressive organization
   - Level 0: All phases inline in single file
   - Level 1: Phase expansion (plan_dir/phase_N.md)
   - Level 2: Stage expansion (phase_dir/stage_N.md) - not used for Lean

8. **Phase Dependencies**: Enable wave-based parallel execution
   - Syntax: `**Dependencies**: Phase_1, Phase_2`
   - Parsed by dependency-analyzer utility
   - Coordinator uses Kahn's algorithm for wave structure

### 3. ProofChecker Lean Project Structure

**Project Location**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/`

**Documentation Structure**:

```
Documentation/
├── README.md - Documentation hub
├── UserGuide/ - User-facing documentation
│   ├── ARCHITECTURE.md - TM logic specification
│   ├── TUTORIAL.md - Getting started guide
│   ├── EXAMPLES.md - Usage examples
│   └── INTEGRATION.md - Integration with model checkers
├── ProjectInfo/ - Project status
│   ├── IMPLEMENTATION_STATUS.md - Module-by-module status tracking
│   ├── KNOWN_LIMITATIONS.md - Gaps, workarounds, roadmap
│   ├── CONTRIBUTING.md - Contribution guidelines
│   └── VERSIONING.md - Semantic versioning policy
├── Development/ - Developer standards
│   ├── LEAN_STYLE_GUIDE.md - Coding conventions
│   ├── MODULE_ORGANIZATION.md - Directory structure
│   ├── PHASED_IMPLEMENTATION.md - Implementation roadmap with waves
│   ├── TACTIC_DEVELOPMENT.md - Custom tactic patterns
│   ├── TESTING_STANDARDS.md - Test requirements
│   └── QUALITY_METRICS.md - Quality targets
└── Reference/
    └── OPERATORS.md - Formal symbols reference
```

**Module Structure**:

```
ProofChecker/
├── Syntax/ - Formula syntax
│   ├── Formula.lean - TM formula definition
│   └── Context.lean - Proof contexts
├── Semantics/ - TM semantics
│   ├── TaskFrame.lean - Task frame structure
│   ├── TaskModel.lean - Task model semantics
│   ├── Truth.lean - Truth at world/history
│   ├── Validity.lean - Validity definitions
│   └── WorldHistory.lean - History helpers
├── ProofSystem/ - Proof system
│   ├── Axioms.lean - TM axioms (MT, M4, M5, TL, MF, TF, etc.)
│   └── Derivation.lean - Proof derivability
├── Theorems/ - Derived theorems
│   └── Perpetuity.lean - Perpetuity principles P1-P6
├── Metalogic/ - Metalogical proofs
│   ├── Soundness.lean - Soundness proof (partial, 15 sorry placeholders)
│   └── Completeness.lean - Completeness proof (11 sorry placeholders)
└── Automation/ - Proof automation
    ├── Tactics.lean - Custom tactics
    └── ProofSearch.lean - Automated proof search
```

**Phased Implementation Roadmap** (from PHASED_IMPLEMENTATION.md):

**Wave 1** (High Priority Foundation, 16-30 hours, all parallel):
- Task 1: Fix CI Flags (1-2 hours)
- Task 2: Add Propositional Axioms (10-15 hours) [CRITICAL PATH]
- Task 3: Complete Archive Examples (5-10 hours)

**Wave 2** (Medium Priority Implementation, 77-113 hours, partial parallelization):
- Task 5: Complete Soundness Proofs (15-20 hours)
- Task 6: Complete Perpetuity Proofs (20-30 hours) [REQUIRES Task 2]
- Task 7: Implement Core Automation (40-60 hours, phased)
- Task 8: Fix WorldHistory (1-2 hours)

**Wave 3** (Low Priority Completion, 110-150 hours):
- Task 9: Begin Completeness Proofs (70-90 hours, phased)
- Task 10: Create Decidability Module (40-60 hours) [REQUIRES Task 9]

**Wave 4** (Future Planning, 20-40 hours):
- Task 11: Plan Layer 1/2/3 Extensions

**Critical Path**: Task 2 → Task 6 → Task 9 → Task 10 (140-205 hours)

**Key Insights for /lean:plan**:
1. Projects have **phased implementation** with wave structure
2. Tasks have **explicit dependencies** (blocking relationships)
3. **Effort estimation** is time ranges (low-high hours)
4. **Module organization** is hierarchical (Syntax, Semantics, ProofSystem, etc.)
5. **Documentation standards** include style guide, testing requirements, quality metrics

### 4. Lean-Specific Planning Requirements

Based on the analysis, a `/lean:plan` command should support:

#### Plan File Format

**Plan Metadata** (Lean-Specific Extensions):

```markdown
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: Brief description (50-100 chars)
- **Status**: [NOT STARTED]
- **Estimated Hours**: 10-15 hours
- **Standards File**: /absolute/path/to/CLAUDE.md
- **Research Reports**: [Mathlib Research](../reports/001-mathlib-research.md)
- **Lean File**: /absolute/path/to/file.lean  # Tier 1 discovery
- **Lean Project**: /absolute/path/to/project/  # lakefile.toml location
```

**Phase Structure with Theorem Dependencies**:

```markdown
### Phase 1: Basic Properties [NOT STARTED]
**Dependencies**: (none - starting phase)
**Estimated Hours**: 3-5 hours

#### Theorems
- [ ] `theorem_add_comm`: Prove commutativity of addition
  - Goal: `∀ a b : Nat, a + b = b + a`
  - Strategy: Use `Nat.add_comm` from Mathlib
  - Complexity: Simple (exact application)

- [ ] `theorem_mul_comm`: Prove commutativity of multiplication
  - Goal: `∀ a b : Nat, a * b = b * a`
  - Strategy: Use `Nat.mul_comm` from Mathlib
  - Complexity: Simple (exact application)

#### Success Criteria
- [ ] All theorems proven (no `sorry` markers)
- [ ] Compilation succeeds (`lake build`)
- [ ] No diagnostics errors

### Phase 2: Derived Properties [NOT STARTED]
**Dependencies**: Phase_1
**Estimated Hours**: 5-8 hours

#### Theorems
- [ ] `theorem_ring_properties`: Prove ring axioms
  - Goal: `∀ a b c : Nat, (a + b) * c = a * c + b * c`
  - Strategy: Use Phase 1 theorems + `ring` tactic
  - Complexity: Medium (tactic combination)
  - Prerequisites: `theorem_add_comm`, `theorem_mul_comm`

#### Success Criteria
- [ ] All theorems proven
- [ ] Tests pass (if test suite exists)
- [ ] Documentation updated
```

**Key Differences from General Plans**:

1. **Theorem-Level Granularity**: Tasks are individual theorems (not files or modules)
2. **Goal Specifications**: Explicit Lean types for theorem statements
3. **Proof Strategies**: High-level approach (Mathlib theorem, tactic, custom proof)
4. **Complexity Assessment**: Simple/Medium/Complex based on proof depth
5. **Prerequisites**: Theorem dependencies (not just phase dependencies)
6. **Lean-Specific Success Criteria**: `lake build`, diagnostics, `sorry` count

#### Research Phase Requirements

The research-specialist should investigate:

1. **Mathlib Theorem Discovery**:
   - Relevant libraries for the formalization domain
   - Applicable theorems for each goal type
   - Type signatures and usage patterns

2. **Proof Pattern Analysis**:
   - Common tactic sequences for goal types
   - Known difficult proofs (may require custom lemmas)
   - Alternative formalization approaches

3. **Project Architecture Review**:
   - Existing module structure
   - Naming conventions
   - Import patterns

4. **Documentation Survey**:
   - Style guide requirements
   - Testing standards
   - Quality metrics

**Research Report Format**:

```markdown
# Mathlib Research Report

## Applicable Theorems

### Commutativity Theorems
- `Nat.add_comm`: `∀ n m : Nat, n + m = m + n`
  - Location: Mathlib.Init.Data.Nat.Basic
  - Usage: Direct application via `exact` tactic
  - Documentation: [Link to Mathlib docs]

### Ring Theory
- `Algebra.Ring.Basic.mul_add`: Distributivity
  - Location: Mathlib.Algebra.Ring.Basic
  - Usage: Rewrite rule or `ring` tactic
  - Prerequisites: Ring instance

## Proof Patterns

### Simple Exact Application
```lean
theorem add_comm (a b : Nat) : a + b = b + a := by
  exact Nat.add_comm a b
```

### Tactic Combination
```lean
theorem distributivity (a b c : Nat) : (a + b) * c = a * c + b * c := by
  rw [Nat.mul_add]
  ring
```

## Formalization Strategy

**Recommended Module Structure**:
- ProofChecker/NewModule/Basic.lean - Definitions
- ProofChecker/NewModule/Theorems.lean - Derived theorems
- ProofCheckerTest/NewModule/TheoremsTest.lean - Tests

**Estimated Complexity**:
- Phase 1 (Basic): 5-10 simple theorems, 3-5 hours
- Phase 2 (Derived): 3-5 medium theorems, 5-8 hours
- Phase 3 (Advanced): 1-2 complex theorems, 8-12 hours
```

#### Planning Phase Requirements

The plan-architect should create:

1. **Dependency Graph**: Theorem prerequisites (not just phase dependencies)
2. **Wave Structure**: Parallel-provable theorems grouped into waves
3. **Effort Estimation**: Based on proof complexity (Simple: 0.5-1h, Medium: 1-3h, Complex: 3-6h)
4. **Proof Strategies**: High-level approach for each theorem
5. **Success Criteria**: Lean-specific validation (compilation, diagnostics, `sorry` count)

**Plan Validation**:
- All theorems have goal specifications
- Proof strategies are actionable (specific Mathlib theorems or tactics)
- Dependencies are acyclic (no circular theorem dependencies)
- Effort estimates are realistic (complexity-based)
- Success criteria are measurable

### 5. /lean:plan Command Design

Based on the analysis, here's the proposed `/lean:plan` command design:

#### Command Syntax

```bash
/lean:plan "<feature-description>" [--file <path>] [--complexity 1-4] [--project <lean-project-path>]
```

**Arguments**:
- `feature-description`: Natural language description of formalization goal
- `--file <path>`: Path to file with detailed prompt (optional)
- `--complexity 1-4`: Research complexity level (default: 3)
- `--project <path>`: Lean project root (default: auto-detect from cwd)

**Examples**:

```bash
# Basic usage
/lean:plan "Formalize TM modal axioms in Lean 4"

# With detailed prompt file
/lean:plan --file prompts/group-theory-formalization.md

# Specify Lean project
/lean:plan "Prove group homomorphism theorems" --project ~/ProofChecker

# Lower complexity (minimal research)
/lean:plan "Prove basic arithmetic commutativity" --complexity 2
```

#### Workflow Architecture

```
/lean:plan [feature-description] [--file <path>] [--complexity 1-4] [--project <path>]

Block 1a: Initial Setup and State Initialization
├─ Capture feature description
├─ Parse complexity flag (default: 3)
├─ Parse --file flag for long prompts
├─ Parse --project flag for Lean project path
├─ Detect Lean project (lakefile.toml validation)
├─ Detect project directory (.claude/)
├─ Source libraries (error-handling, state-persistence, workflow-state-machine)
└─ Initialize workflow state

Block 1b: Topic Name File Path Pre-Calculation
├─ Pre-calculate TOPIC_NAME_FILE path
├─ Validate path is absolute
└─ Persist for Block 1b-exec and Block 1c

Block 1b-exec: Topic Name Generation (Hard Barrier Invocation)
└─ Invoke topic-naming-agent via Task tool

Block 1c: Hard Barrier Validation
└─ Validate topic name file exists at pre-calculated path

Block 1d: Topic Path Initialization
├─ Read topic name from agent output file
├─ Fallback naming if agent failed
├─ Create classification JSON for initialize_workflow_paths
├─ Initialize workflow paths with topic name
├─ Archive prompt file (if --file was used)
└─ Persist Lean project path and file

Block 1e: Research Initiation (Lean-Specific)
└─ Invoke lean-research-specialist agent via Task tool
    ├─ Mathlib theorem discovery
    ├─ Proof pattern analysis
    ├─ Project architecture review
    └─ Documentation survey

Block 2: Research Verification and Planning Setup
├─ Verify research artifacts
├─ Transition to PLAN state
├─ Prepare plan path
├─ Extract project standards
├─ Extract Lean project standards (LEAN_STYLE_GUIDE.md, TESTING_STANDARDS.md)
└─ Invoke lean-plan-architect agent via Task tool

Block 3: Plan Verification and Completion
├─ Verify plan artifacts (Lean-specific validation)
│   ├─ Plan file exists and size >= 500 bytes
│   ├─ All phases have theorem specifications
│   ├─ All theorems have goal types
│   └─ Dependencies are acyclic
├─ Detect Phase 0 (Standards Divergence)
├─ Transition to COMPLETE state
├─ Display console summary (Lean-specific metrics)
└─ Emit PLAN_CREATED signal
```

**Lean-Specific Validation** (Block 3):

```bash
# Validate theorem specifications
THEOREM_COUNT=$(grep -c "^- \[ \] \`theorem_" "$PLAN_PATH" || echo "0")
if [ "$THEOREM_COUNT" -eq 0 ]; then
  echo "ERROR: Plan has no theorem specifications"
  exit 1
fi

# Validate goal specifications
GOAL_COUNT=$(grep -c "Goal:" "$PLAN_PATH" || echo "0")
if [ "$GOAL_COUNT" -ne "$THEOREM_COUNT" ]; then
  echo "WARNING: Not all theorems have goal specifications ($GOAL_COUNT/$THEOREM_COUNT)"
fi

# Validate dependency acyclicity (via dependency-analyzer)
bash "$CLAUDE_PROJECT_DIR/.claude/lib/util/dependency-analyzer.sh" "$PLAN_PATH" > /tmp/lean_plan_deps.json
CYCLE_CHECK=$(jq -r '.errors[] | select(.type == "circular_dependency")' /tmp/lean_plan_deps.json)
if [ -n "$CYCLE_CHECK" ]; then
  echo "ERROR: Circular theorem dependencies detected"
  echo "$CYCLE_CHECK"
  exit 1
fi
```

#### Agent Specifications

**lean-research-specialist Agent** (New):

**Frontmatter**:
```yaml
---
allowed-tools: Read, Grep, Glob, Bash, WebSearch
description: Lean 4 formalization research specialist for Mathlib and proof pattern analysis
model: sonnet-4.5
model-justification: Deep Mathlib analysis, proof pattern recognition, formalization strategy
---
```

**Behavioral Guidelines**:

1. **Mathlib Theorem Discovery**
   - Use `lean_local_search` (if MCP available) or grep to search Lean project
   - Use WebSearch for Mathlib documentation
   - Document theorem names, types, locations, usage patterns

2. **Proof Pattern Analysis**
   - Identify common tactic sequences for goal types
   - Note difficult proofs requiring custom lemmas
   - Document alternative formalization approaches

3. **Project Architecture Review**
   - Read existing module structure
   - Extract naming conventions from style guide
   - Document import patterns

4. **Documentation Survey**
   - Read LEAN_STYLE_GUIDE.md (if exists)
   - Read TESTING_STANDARDS.md (if exists)
   - Extract quality metrics

**Output Signal**:
```markdown
REPORT_CREATED: /path/to/reports/001-lean-formalization-research.md
```

**lean-plan-architect Agent** (Modified from plan-architect):

**Frontmatter**:
```yaml
---
allowed-tools: Read, Write, Bash
description: Lean 4 formalization implementation plan creation specialist
model: sonnet-4.5
model-justification: Theorem dependency analysis, proof strategy formulation, effort estimation
---
```

**Behavioral Guidelines** (Extensions for Lean):

1. **Theorem Dependency Analysis**
   - Extract theorem prerequisites from research reports
   - Build dependency graph (theorem → theorem edges)
   - Validate acyclicity

2. **Wave Structure Generation**
   - Group independent theorems into parallel waves
   - Respect theorem dependencies (not just phase dependencies)
   - Optimize for parallelization (40-60% time savings target)

3. **Proof Strategy Formulation**
   - Specify Mathlib theorems to use (from research reports)
   - Suggest tactic sequences (exact, rw, ring, simp, etc.)
   - Assess complexity (Simple/Medium/Complex)

4. **Effort Estimation**
   - Simple theorems: 0.5-1 hour (exact application)
   - Medium theorems: 1-3 hours (tactic combination)
   - Complex theorems: 3-6 hours (custom lemmas, deep reasoning)

5. **Lean-Specific Metadata**
   - Include `**Lean File**` field in metadata
   - Include `**Lean Project**` field (lakefile.toml location)
   - Add theorem count metrics to summary

**Output Signal**:
```markdown
PLAN_CREATED: /path/to/plans/001-lean-formalization-plan.md
```

#### Integration with /lean Command

After plan creation, users execute the plan with:

```bash
/lean .claude/specs/NNN_topic/plans/001-formalization-plan.md --prove-all
```

The `/lean` command:
1. Detects plan-based mode (file ends with `.md`)
2. Loads plan file
3. Discovers Lean file via 3-tier discovery (Tier 1: metadata)
4. Invokes lean-coordinator for wave-based execution
5. lean-coordinator parses phase dependencies
6. Invokes lean-implementer for each wave (parallel execution)
7. Updates progress markers in plan file
8. Creates proof summaries in summaries/ directory

**Complete Workflow**:

```bash
# 1. Research and plan formalization
/lean:plan "Formalize TM perpetuity principles P4-P6"

# Output: .claude/specs/032_lean_perpetuity/plans/001-perpetuity-formalization-plan.md

# 2. Execute plan
/lean .claude/specs/032_lean_perpetuity/plans/001-perpetuity-formalization-plan.md --prove-all

# Output: Proofs completed, summaries in .claude/specs/032_lean_perpetuity/summaries/

# 3. Update TODO.md
/todo
```

---

## Recommendations

### Implementation Plan

**Phase 1: Command Creation** (2-3 hours)

1. Create `/lean:plan` command file following `/plan` pattern
   - File: `.claude/commands/lean_plan.md`
   - Argument parsing (feature description, --file, --complexity, --project)
   - Lean project detection (lakefile.toml validation)
   - Workflow state initialization
   - Topic naming (reuse topic-naming-agent)

2. Add Lean-specific validation in Block 3
   - Theorem count validation
   - Goal specification validation
   - Dependency acyclicity check (via dependency-analyzer)

**Phase 2: Agent Creation** (3-4 hours)

1. Create `lean-research-specialist` agent
   - File: `.claude/agents/lean-research-specialist.md`
   - Mathlib search strategies
   - Proof pattern analysis workflow
   - Research report template

2. Modify `plan-architect` for Lean support (or create `lean-plan-architect`)
   - Theorem dependency analysis
   - Wave structure generation
   - Proof strategy formulation
   - Lean-specific metadata fields

**Phase 3: Testing & Documentation** (2-3 hours)

1. Test with sample formalization goals
   - Simple: "Prove basic arithmetic properties"
   - Medium: "Formalize group homomorphism theorems"
   - Complex: "Formalize TM perpetuity principles"

2. Create command guide
   - File: `.claude/docs/guides/commands/lean-plan-command-guide.md`
   - Usage examples
   - Integration with /lean workflow
   - Troubleshooting

3. Update command reference
   - Add to `.claude/docs/reference/standards/command-reference.md`

**Total Effort**: 7-10 hours

### Alternative Approach: Extend /plan for Lean

Instead of creating a separate `/lean:plan` command, extend `/plan` to detect Lean projects and delegate to lean-research-specialist automatically:

**Detection Logic** (in `/plan` command):

```bash
# Detect Lean project in feature description or --project flag
if [[ "$FEATURE_DESCRIPTION" =~ lean|Lean4 ]] || [ -n "${LEAN_PROJECT_PATH:-}" ]; then
  RESEARCH_AGENT="lean-research-specialist"
  PLAN_AGENT="lean-plan-architect"
else
  RESEARCH_AGENT="research-specialist"
  PLAN_AGENT="plan-architect"
fi
```

**Advantages**:
- ✅ No new command (zero learning curve)
- ✅ Automatic Lean detection
- ✅ Reuses existing /plan infrastructure
- ✅ Less maintenance burden

**Disadvantages**:
- ❌ No Lean-specific flags (--project)
- ❌ Generic command name (less explicit)
- ❌ Potential confusion (when to use /plan vs /lean:plan)

**Recommendation**: Start with **separate `/lean:plan` command** for explicitness and Lean-specific features, then consider consolidation if usage patterns favor it.

### Design Decisions

1. **Command Name**: `/lean:plan` (colon separator matches existing pattern, e.g., could have `/plan:lean` as alias)

2. **Agent Reuse**: Create `lean-research-specialist` (new) and `lean-plan-architect` (modified from plan-architect)

3. **Plan Format**: Extend standard plan format with Lean-specific metadata fields

4. **Validation**: Add Lean-specific validation in Block 3 (theorem count, goals, dependency acyclicity)

5. **Integration**: Plan execution via existing `/lean` command (no changes needed)

6. **Documentation**: Create dedicated command guide with Lean-specific examples

---

## Success Criteria

Implementation is successful if:

- ✅ `/lean:plan` command creates valid Lean implementation plans
- ✅ Plans include Mathlib research with applicable theorem links
- ✅ Plans specify proof strategies for each theorem
- ✅ Plans validate theorem dependencies (acyclicity check)
- ✅ Plans execute successfully with `/lean` command
- ✅ Documentation provides clear usage examples
- ✅ Integration with existing workflow (research → plan → implement → test)

---

## Related Documentation

**Existing Commands**:
- `/plan` - `.claude/commands/plan.md`
- `/lean` - `.claude/commands/lean.md`

**Agents**:
- `research-specialist` - `.claude/agents/research-specialist.md`
- `plan-architect` - `.claude/agents/plan-architect.md`
- `lean-implementer` - `.claude/agents/lean-implementer.md`
- `lean-coordinator` - `.claude/agents/lean-coordinator.md`

**Libraries**:
- `dependency-analyzer` - `.claude/lib/util/dependency-analyzer.sh`
- `checkbox-utils` - `.claude/lib/plan/checkbox-utils.sh`

**Standards**:
- Plan Metadata Standard - `.claude/docs/reference/standards/plan-metadata-standard.md`
- Directory Protocols - `.claude/docs/concepts/directory-protocols.md`

**ProofChecker Documentation**:
- PHASED_IMPLEMENTATION.md - `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/Development/PHASED_IMPLEMENTATION.md`
- LEAN_STYLE_GUIDE.md - `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/Development/LEAN_STYLE_GUIDE.md`

---

**Report Complete**

**Implementation Estimate**: 7-10 hours

**Recommended Starting Point**: Create `/lean:plan` command following `/plan` pattern with Lean-specific agent delegation

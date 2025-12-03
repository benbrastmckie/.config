# Lean Command Orchestrator Design Research Report

## Metadata
- **Date**: 2025-12-02
- **Agent**: research-specialist
- **Topic**: Lean command orchestrator implementation strategy
- **Report Type**: codebase analysis and architectural design
- **Research Complexity**: 3
- **Related Spec**: 025_lean_mcp_command_orchestration_strategy

## Executive Summary

This report provides comprehensive research for implementing a `/lean` command orchestrator that integrates the lean-lsp-mcp server into the existing .claude/ workflow architecture. After analyzing the `/implement` command structure, implementer-coordinator agent patterns, and Lean-specific development requirements, the recommended approach is to create a **specialized lean-implementer agent** that integrates with the existing `/implement` command workflow rather than creating an entirely separate `/lean` command. This approach maximizes code reuse, maintains architectural consistency with existing orchestrators, and leverages the mature iteration management and state machine infrastructure already present in `/implement`.

## Findings

### 1. Current Architecture Analysis

#### 1.1 /implement Command Structure

The `/implement` command (`.claude/commands/implement.md`) follows a well-established 5-block architecture:

**Block 1a: Implementation Setup** (Lines 23-398)
- 2-block argument capture pattern (TEMP_FILE → parsing)
- Three-tier library sourcing (error-handling.sh → state-persistence.sh → workflow-state-machine.sh)
- Pre-flight validation (validates library functions loaded correctly)
- State machine initialization
- State transition to IMPLEMENT

**Block 1b: Implementer-Coordinator Invocation** (Lines 400-550)
- Hard barrier pattern: setup → execute → verify
- Summary output path calculation
- Task tool invocation with input contract (plan_path, topic_path, artifact_paths, continuation_context, iteration, max_iterations)

**Block 1c: Implementation Verification** (Lines 552-680)
- Summary file existence validation (≥100 bytes)
- Iteration metadata parsing (requires_continuation, work_remaining, context_usage_percent)
- Continuation loop decision logic

**Block 1d: Phase Update** (Lines 682-750)
- Plan checkbox updates via mark_phase_complete
- State persistence via save_completed_states_to_state
- Plan status marker updates ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])

**Block 2: Completion** (Lines 752-850)
- State transition to COMPLETE
- 4-section console summary (Summary, Phases, Artifacts, Next Steps)
- IMPLEMENTATION_COMPLETE signal emission
- State file preservation for /test handoff
- Checkpoint cleanup

**Key Characteristics**:
- Multi-iteration support (max 5 iterations with context threshold at 90%)
- Checkpoint-based resumption (`.claude/data/checkpoints/implement_checkpoint.json`)
- Auto-resume capability (detects most recent plan if none specified)
- Dry-run mode (--dry-run flag)
- Configurable iteration limits (--max-iterations=N, --context-threshold=N)

#### 1.2 Implementer-Coordinator Agent

The `implementer-coordinator.md` agent (`.claude/agents/implementer-coordinator.md`) orchestrates wave-based parallel phase execution:

**Core Responsibilities** (Lines 11-22):
1. Dependency Analysis - Invokes dependency-analyzer utility to build execution structure
2. Wave Orchestration - Executes phases wave-by-wave with parallel executors
3. Progress Monitoring - Collects real-time updates from executors
4. State Management - Maintains implementation state across waves
5. Failure Handling - Detects failures, marks phases, continues independent work
6. Result Aggregation - Collects completion reports and metrics

**Input Contract** (Lines 28-52):
```yaml
plan_path: /absolute/path/to/plan.md
topic_path: /absolute/path/to/topic/
artifact_paths:
  reports: /topic/reports/
  plans: /topic/plans/
  summaries: /topic/summaries/
  debug: /topic/debug/
  outputs: /topic/outputs/
  checkpoints: /home/user/.claude/data/checkpoints/
continuation_context: null  # Or path to previous summary
iteration: 1  # Current iteration (1-5)
max_iterations: 5
context_threshold: 85
```

**Output Signal** (not shown but referenced in implement.md:183):
```yaml
IMPLEMENTATION_COMPLETE:
  summary_path: /path/to/summary.md
  plan_file: /path/to/plan.md
  work_remaining: 0 (or list of incomplete phases)
  context_exhausted: false
  context_usage_percent: 85%
  requires_continuation: false
  next_command: "/test /path/to/plan.md"
```

**Workflow Steps** (Lines 54-200):
1. **Plan Structure Detection** - Detects Level 0 (inline), Level 1 (phase files), or Level 2 (stage files)
2. **Dependency Analysis** - Invokes dependency-analyzer.sh to generate wave structure
3. **Iteration Management** - Estimates context usage, saves checkpoints if threshold exceeded
4. **Wave Execution** - Executes phases in parallel waves, delegates to implementation-executor
5. **Result Aggregation** - Collects summaries from all executors

**Key Features**:
- Supports progressive plan expansion (Level 0 → Level 1 → Level 2)
- Parallel phase execution with dependency analysis (40-60% time savings)
- Context-aware iteration management (halts at 85% context usage by default)
- Checkpoint-based resumption (v2.1 schema with iteration fields)

#### 1.3 Implementation-Executor Agent

Referenced in implementer-coordinator.md but not read directly. Based on context from implement-command-guide.md (Lines 129-157):

**Core Responsibilities**:
- Executes single phase tasks
- Updates plan checkboxes ([ ] → [x])
- Updates phase status markers ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
- Creates git commits (via spec-updater)
- Returns phase completion summaries

**Real-Time Progress Tracking**:
- Calls `add_in_progress_marker()` at phase start
- Updates task checkboxes during execution
- Calls `add_complete_marker()` at phase end
- Non-fatal marker updates (logged as warnings on failure)

### 2. Lean-Specific Requirements Analysis

#### 2.1 Lean Development Workflow Differences

From LEAN_STYLE_GUIDE.md and TACTIC_DEVELOPMENT.md analysis:

**Standard Code Implementation**:
- Multi-file feature development (backend, frontend, API)
- Test-driven development (write tests, then run tests)
- Phase-level granularity (each phase = 1+ files)
- Build verification (compile, lint, test execution)

**Lean Proof Development**:
- Single-theorem granularity (proof-level iteration)
- Interactive proof refinement (inspect goals → apply tactics → verify)
- Tactic-level granularity (each tactic = proof step)
- Type-checker verification (no `sorry`, `#check` succeeds)

**Key Differences**:

| Aspect | General Code | Lean Proofs |
|--------|-------------|-------------|
| **Goal** | Feature implementation | Proof completion |
| **Success Criteria** | Tests pass | No `sorry`, `#check` succeeds |
| **Iteration** | Multi-phase (files, modules) | Single theorem (tactics) |
| **Search** | Documentation, examples | Theorem libraries (Mathlib) |
| **Validation** | Test suite execution | Type checker, compiler |
| **Tools** | Compiler, linter, tests | LSP, goal inspection, library search |
| **Context** | Codebase architecture | Proof state, available theorems |

#### 2.2 lean-lsp-mcp Integration Status

From 001-lean-mcp-command-integration.md (Spec 025):

**Operational Status** (Lines 25-40):
- ✅ MCP server installed and configured in `~/lean-test-project/.mcp.json`
- ✅ 17 tools available via stdio transport
- ✅ Neovim integration with `<leader>ri` keybinding
- ✅ Integration tested and validated (automated tests passing)

**Available MCP Tools** (Lines 42-61):

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

**Search Tools** (rate limited: 3 requests/30s combined):
- `lean_local_search` - Local ripgrep search (no rate limit)
- `lean_leansearch` - Natural language theorem search
- `lean_loogle` - Type/constant/lemma search
- `lean_leanfinder` - Semantic Mathlib search
- `lean_state_search` - Goal-based applicable theorem search
- `lean_hammer_premise` - Premise search based on proof state

**Advanced**:
- `lean_multi_attempt` - Multi-proof screening
- `lean_declaration_file` - Declaration source lookup

**Current Usage Pattern**: Claude Code accesses lean-lsp-mcp tools automatically when invoked in Lean projects (via `<leader>a` mappings).

#### 2.3 Lean Code Standards and Best Practices

From LEAN_STYLE_GUIDE.md analysis:

**Naming Conventions** (Lines 6-60):
- Type variables: Greek letters (α, β, γ) or uppercase (A, B, C)
- Functions/Theorems: snake_case (`soundness`, `truth_at`, `swap_past_future`)
- Types/Structures: PascalCase (`Formula`, `TaskFrame`, `WorldHistory`)
- Comments: Wrap formal symbols in backticks (`` `□φ → φ` ``)

**Formatting Standards** (Lines 77-259):
- Maximum 100 characters per line
- 2-space indentation (no tabs)
- Flush-left declarations (no indentation for `def`, `theorem`, `lemma`)
- Single space around binary operators
- Unicode operator notation (`□φ` for necessity, `◇φ` for possibility)

**Documentation Requirements** (Lines 293-374):
- Module docstrings (purpose, main definitions, main theorems, implementation notes, references)
- Declaration docstrings for all public definitions/theorems
- Example formatting in docstrings
- Deprecation protocol with `@[deprecated]` attribute

**Import Organization** (Lines 263-290):
1. Standard library imports
2. Mathlib imports
3. Project imports (ProofChecker.*)
4. Blank line between groups

From METAPROGRAMMING_GUIDE.md analysis:

**Tactic Development Patterns** (Lines 46-90):
- Essential imports: `Lean.Elab.Tactic`, `Lean.Meta.Basic`, `Lean.Expr`, `Lean.MVarId`
- Goal management: `getMainGoal`, `goal.getType`, `goal.assign`
- Expression pattern matching: Destructure formula structure (`.app`, `.const`)
- Proof term construction: `mkAppM`, `mkConst`

**Error Handling** (Lines 399-495):
- Use `throwError` with descriptive messages
- Include expected vs actual patterns in errors
- Handle recoverable errors with try...catch
- Provide helpful error context

From TACTIC_DEVELOPMENT.md analysis:

**Tactic Implementation Approaches** (Lines 495-606):
1. **Macro-Based** (simplest): For tactics that expand to existing tactics
2. **elab_rules** (recommended): For pattern-matched tactics with goal inspection
3. **Direct TacticM** (advanced): For complex tactics with iteration/backtracking

**Aesop Integration** (Lines 283-418):
- `@[aesop safe]` - Safe rules always applied
- `@[aesop norm simp]` - Normalization rules for preprocessing
- Custom rule sets (`declare_aesop_rule_sets [TMLogic]`)
- `tm_auto` tactic expands to `aesop (rule_sets [TMLogic])`

**Testing Requirements** (Lines 577-619):
- Unit tests for each tactic
- Performance tests on complex formulas
- `fail_if_success` for negative tests

### 3. Architectural Design Options

#### Option A: Standalone /lean Command

**Architecture**:
```
/lean [plan-file | theorem-name] [--prove | --verify]
├─ Block 1a: Setup & Lean Project Detection
│   ├─ Verify Lean 4 project (lakefile.toml)
│   ├─ Detect MCP server availability
│   ├─ Load plan or identify theorem target
│   └─ Initialize workflow state
├─ Block 1b: lean-coordinator invocation [HARD BARRIER]
│   └─ Delegates to: lean-implementer agent
│       ├─ Proof goal inspection (lean_goal)
│       ├─ Theorem search (lean_leansearch, lean_loogle)
│       ├─ Multi-attempt screening (lean_multi_attempt)
│       ├─ Tactic application and verification
│       └─ Returns: PROOF_COMPLETE signal
├─ Block 1c: Verification & Diagnostics
│   ├─ Validate proof completeness (no `sorry`)
│   ├─ Check diagnostics (lean_diagnostic_messages)
│   └─ Persist proof summary
└─ Block 2: Completion & Summary
    ├─ Create proof summary artifact
    ├─ Link to plan (if provided)
    └─ Emit PROOF_COMPLETE signal
```

**Advantages**:
- ✅ Lean-specific features (--prove-all, --verify flags)
- ✅ Dedicated workflow for proof development
- ✅ Lean-specific summary format (theorem statistics, tactic usage metrics)
- ✅ Clear semantic distinction from general /implement

**Disadvantages**:
- ❌ Code duplication with /implement (5-block structure, iteration logic, state machine)
- ❌ Maintenance burden (another command to maintain, 2 orchestrators to keep in sync)
- ❌ Learning curve (users must learn new command syntax)
- ❌ Plan file requirement for batch mode (creates friction)

**Implementation Effort**: 3-5 hours
- Command creation: 1-2 hours
- lean-coordinator agent: 1-2 hours
- Testing & documentation: 1 hour

#### Option B: lean-implementer Agent with Auto-Routing

**Architecture**:
```
/implement [lean-plan.md]
├─ Block 1a: Setup (unchanged)
├─ Block 1b: implementer-coordinator invocation
│   └─ implementer-coordinator detects .lean files
│       ├─ If .lean detected → invoke lean-implementer
│       └─ Else → invoke implementation-executor
├─ Block 1c-2: Verification & Completion (unchanged)
```

**implementer-coordinator Enhancement** (Lines 738-770 in current file):
```markdown
## Lean File Detection (Auto-Routing)

When a phase contains `.lean` files, delegate to lean-implementer instead of implementation-executor:

**Detection Logic**:
```bash
# Check if phase tasks mention Lean files
if grep -qE '\.lean\b' <<< "$PHASE_TASKS"; then
  EXECUTOR_AGENT="lean-implementer"
else
  EXECUTOR_AGENT="implementation-executor"
fi
```

**Invocation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute Lean proof development (Phase $PHASE_NUM)"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/${EXECUTOR_AGENT}.md
    ...
  "
}
```
```

**lean-implementer Agent Specification**:

**Frontmatter**:
```yaml
---
allowed-tools: Read, Edit, Bash
description: AI-assisted Lean 4 theorem proving and formalization specialist
model: sonnet-4.5
model-justification: Complex proof search, tactic generation, Mathlib theorem discovery
fallback-model: sonnet-4.5
---
```

**Core Capabilities**:
1. **Proof Goal Analysis**
   - Extract proof goals via `lean_goal` MCP tool (Bash: `uvx --from lean-lsp-mcp lean-goal <file> <line> <col>`)
   - Identify goal type, hypotheses, target
   - Assess proof complexity

2. **Theorem Discovery**
   - Search Mathlib via `lean_leansearch` (natural language: `uvx lean-leansearch "commutativity natural number addition"`)
   - Type-based search via `lean_loogle` (`uvx lean-loogle "Nat → Nat → Nat"`)
   - State-based search via `lean_state_search` (finds applicable theorems for current proof state)
   - Local project search via `lean_local_search` (ripgrep wrapper, no rate limits)

3. **Tactic Exploration**
   - Generate candidate tactics based on goal type (pattern matching on goal structure)
   - Use `lean_multi_attempt` to test multiple approaches in parallel
   - Evaluate which tactics make progress (check diagnostics after each attempt)

4. **Proof Completion**
   - Apply successful tactics via Edit tool (replace `sorry` with tactic sequences)
   - Verify proof compiles via `lean_build` (project-wide compilation)
   - Check diagnostics for errors via `lean_diagnostic_messages`
   - Iterate until proof complete (no `sorry` markers remaining)

5. **Documentation**
   - Explain tactic choices with reasoning (docstrings per LEAN_STYLE_GUIDE.md)
   - Link to Mathlib theorems used (references section with URLs)
   - Create proof summary artifact (summaries/ directory)

**Input Contract** (same as implementation-executor):
```yaml
plan_path: /absolute/path/to/plan.md
topic_path: /absolute/path/to/topic/
phase_number: 2
phase_content: "### Phase 2: Prove Commutativity\n- [ ] Prove add_comm theorem..."
artifact_paths:
  summaries: /topic/summaries/
  debug: /topic/debug/
```

**Output Signal** (compatible with implementation-executor):
```yaml
IMPLEMENTATION_COMPLETE: 1
plan_file: /path/to/plan.md
topic_path: /path/to/topic
summary_path: /topic/summaries/002-proof-summary.md
work_remaining: 0
theorems_proven: ["add_comm", "mul_comm"]
tactics_used: ["exact", "rw", "simp"]
diagnostics: []
```

**Advantages**:
- ✅ No new command (reuses /implement infrastructure)
- ✅ Zero learning curve (users continue using /implement)
- ✅ Automatic detection (no manual specification)
- ✅ Code reuse (shares 5-block structure, iteration management, state machine)
- ✅ Future-proof (new commands automatically support Lean)
- ✅ Minimal maintenance (single agent definition, no command changes)

**Disadvantages**:
- ❌ No Lean-specific flags (cannot have --prove-all or --verify without changing /implement)
- ❌ Detection overhead (must check for .lean files in every phase)
- ❌ Generic output format (no Lean-specific summary fields without extending IMPLEMENTATION_COMPLETE signal)

**Implementation Effort**: 2.5-3.5 hours
- lean-implementer agent: 1.5-2 hours
- implementer-coordinator detection logic: 30 minutes
- Testing & documentation: 30 minutes

#### Option C: Hybrid Approach (Recommended)

**Phase 1: Implement Option B** (2.5-3.5 hours)
- Create lean-implementer agent
- Add Lean detection to implementer-coordinator
- Test with /implement command

**Phase 2: Add /lean Command Wrapper** (Optional, 1-2 hours)
- Create /lean command that delegates to /implement
- Add Lean-specific argument parsing (--prove-all, --verify)
- Map to /implement invocation with Lean plan

**Rationale**:
1. **Minimize upfront investment**: Start with auto-routing (Option B)
2. **Validate approach**: Test lean-implementer with /implement first
3. **Defer specialization**: Only create /lean if Lean-specific flags become essential
4. **Maximize reuse**: lean-implementer works with both /implement and /lean

**Example /lean Command** (if Phase 2 implemented):
```markdown
# /lean - Lean Theorem Proving Command

Wrapper around /implement with Lean-specific argument parsing.

## Block 1: Argument Transformation

```bash
# Parse Lean-specific arguments
LEAN_FILE="${ARGS_ARRAY[0]:-}"
MODE="${ARGS_ARRAY[1]:---prove}"  # --prove (default) or --verify

# Transform to /implement invocation
if [ "$MODE" = "--prove-all" ]; then
  # Create temporary plan for all unproven theorems
  PLAN_FILE=$(mktemp)
  create_lean_plan_from_file "$LEAN_FILE" > "$PLAN_FILE"
  /implement "$PLAN_FILE"
elif [ "$MODE" = "--verify" ]; then
  # Invoke with verification flag
  /implement "$LEAN_FILE" --verify
else
  # Single theorem mode
  /implement "$LEAN_FILE"
fi
```
```

### 4. Lean-Implementer Agent Detailed Specification

#### 4.1 Behavioral Guidelines

**STEP 1: Identify Unproven Theorems**

```bash
# Search for 'sorry' markers in Lean file
grep -n "sorry" "$LEAN_FILE" | while read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  echo "Unproven theorem at line $LINE_NUM"
done
```

**STEP 2: Extract Proof Goals**

```bash
# Use lean_goal MCP tool to inspect proof state
uvx --from lean-lsp-mcp lean-goal "$LEAN_FILE" $LINE_NUM $COL_NUM

# Example output:
# {
#   "goals": [
#     {
#       "type": "a + b = b + a",
#       "hypotheses": ["a : Nat", "b : Nat"],
#       "context": "..."
#     }
#   ]
# }
```

**STEP 3: Search Applicable Theorems**

```bash
# Natural language search (rate limited: 3 requests/30s)
uvx --from lean-lsp-mcp lean-leansearch "natural number addition commutativity"

# Type-based search (rate limited)
uvx --from lean-lsp-mcp lean-loogle "∀ n m : Nat, n + m = m + n"

# State-based search (rate limited)
uvx --from lean-lsp-mcp lean-state-search "$LEAN_FILE" $LINE_NUM $COL_NUM

# Local search (no rate limit)
uvx --from lean-lsp-mcp lean-local-search "add_comm"
```

**Output Example**:
```json
{
  "results": [
    {
      "name": "Nat.add_comm",
      "type": "∀ n m : Nat, n + m = m + n",
      "docstring": "Commutativity of natural number addition",
      "module": "Mathlib.Data.Nat.Basic"
    }
  ]
}
```

**STEP 4: Generate Candidate Tactics**

Based on goal type pattern matching:

**Pattern: `a + b = b + a` (commutativity)**
→ Search for `*_comm` theorems
→ Try `exact Nat.add_comm a b`

**Pattern: `a * (b * c) = (a * b) * c` (associativity)**
→ Search for `*_assoc` theorems
→ Try `exact Nat.mul_assoc a b c`

**Pattern: `□φ → φ` (modal logic)**
→ Search for modal axioms
→ Try `apply Axiom.modal_t`

**STEP 5: Test Tactics via lean_multi_attempt**

```bash
# Test multiple proof strategies in parallel
uvx --from lean-lsp-mcp lean-multi-attempt "$LEAN_FILE" $LINE_NUM $COL_NUM \
  '["exact Nat.add_comm a b", "rw [Nat.add_comm]", "simp [Nat.add_comm]"]'

# Output: Success/failure status for each tactic
```

**STEP 6: Apply Successful Tactics**

Use Edit tool to replace `sorry`:

```lean
-- Before:
theorem add_comm (a b : Nat) : a + b = b + a := by
  sorry

-- After:
theorem add_comm (a b : Nat) : a + b = b + a := by
  exact Nat.add_comm a b
```

**STEP 7: Verify Proof Completion**

```bash
# Build project to verify proof compiles
uvx --from lean-lsp-mcp lean-build "$LEAN_PROJECT_DIR"

# Check diagnostics for errors
uvx --from lean-lsp-mcp lean-diagnostic-messages "$LEAN_FILE"

# Expected output if successful:
# {"diagnostics": []}
```

**STEP 8: Create Proof Summary**

```markdown
# Proof Summary: add_comm

## Metadata
- **Date**: 2025-12-02
- **File**: MyTheorems.lean
- **Theorem**: add_comm
- **Status**: ✅ Complete

## Proof Strategy

Applied commutativity theorem from Mathlib:

**Tactic**: `exact Nat.add_comm a b`

**Reasoning**: The goal `a + b = b + a` matches the type signature of `Nat.add_comm : ∀ n m : Nat, n + m = m + n` exactly. No additional rewriting needed.

## Theorems Used

- `Nat.add_comm` (Mathlib.Data.Nat.Basic)

## Diagnostics

No errors or warnings.

## References

- [Nat.add_comm documentation](https://leanprover-community.github.io/mathlib4_docs/Mathlib/Data/Nat/Basic.html#Nat.add_comm)
```

#### 4.2 Error Handling

**MCP Tool Rate Limits**:

External search tools (`lean_leansearch`, `lean_loogle`, `lean_leanfinder`, `lean_state_search`, `lean_hammer_premise`) share a combined rate limit of 3 requests per 30 seconds.

**Strategy**:
1. Prioritize `lean_local_search` (no rate limit)
2. Use one external search tool per theorem (rotate between tools)
3. If rate limited, wait 30 seconds before retrying
4. Fallback to pattern-based tactic generation

**Proof Verification Failures**:

If `lean_build` reports errors:
1. Parse diagnostic messages via `lean_diagnostic_messages`
2. Extract error location and type
3. Backtrack to previous proof step
4. Try alternative tactics
5. If all attempts fail, leave `sorry` with TODO comment

**Example**:
```lean
theorem complex_proof (a b : Nat) : a + b = b + a := by
  sorry  -- TODO: Requires Nat.add_comm, but type mismatch in hypotheses
```

#### 4.3 Progress Reporting

**Real-Time Progress Markers**:

```
PROGRESS: Analyzing proof goals in MyTheorems.lean
PROGRESS: Found 3 unproven theorems
PROGRESS: Searching Mathlib for add_comm
PROGRESS: Found applicable theorem: Nat.add_comm
PROGRESS: Testing tactic: exact Nat.add_comm a b
PROGRESS: Tactic successful, applying to proof
PROGRESS: Verifying proof compilation
PROGRESS: Proof complete, creating summary
```

**Summary Statistics**:

```yaml
theorems_total: 5
theorems_proven: 4
theorems_partial: 1
theorems_failed: 0
tactics_used: ["exact", "rw", "simp"]
mathlib_theorems_applied: ["Nat.add_comm", "Nat.mul_comm"]
total_time: "2 minutes 30 seconds"
```

### 5. Implementation Roadmap

#### Phase 1: lean-implementer Agent Creation (1.5-2 hours)

**File**: `.claude/agents/lean-implementer.md`

**Sections**:
1. **Frontmatter** (allowed-tools, description, model)
2. **Role** (AI-assisted Lean 4 theorem proving specialist)
3. **Core Capabilities** (8 steps from STEP 1-8 above)
4. **Input Contract** (plan_path, topic_path, phase_number, phase_content, artifact_paths)
5. **Output Signal** (IMPLEMENTATION_COMPLETE with Lean-specific fields)
6. **Error Handling** (rate limits, proof failures)
7. **Progress Reporting** (real-time markers, summary statistics)
8. **Example Usage** (sample invocations with input/output)

**References**:
- LEAN_STYLE_GUIDE.md (naming, formatting, documentation requirements)
- METAPROGRAMMING_GUIDE.md (tactic patterns, goal management)
- TACTIC_DEVELOPMENT.md (Aesop integration, testing requirements)

#### Phase 2: implementer-coordinator Enhancement (30 minutes)

**File**: `.claude/agents/implementer-coordinator.md`

**Addition at Line 738** (after Wave Execution section):

```markdown
## Lean File Detection and Auto-Routing

When a phase contains `.lean` files, delegate to `lean-implementer` instead of `implementation-executor`.

### Detection Logic

```bash
# Extract phase tasks (assumes markdown checkbox format)
PHASE_TASKS=$(extract_phase_tasks "$PLAN_FILE" "$PHASE_NUM")

# Check if any task references .lean files
if grep -qE '\.lean\b' <<< "$PHASE_TASKS"; then
  EXECUTOR_AGENT="lean-implementer"
  EXECUTOR_DESC="Lean proof development"
else
  EXECUTOR_AGENT="implementation-executor"
  EXECUTOR_DESC="General implementation"
fi
```

### Invocation Pattern

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute $EXECUTOR_DESC (Phase $PHASE_NUM)"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/${EXECUTOR_AGENT}.md

    **Input Contract**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - phase_number: $PHASE_NUM
    - phase_content: \"\"\"
$PHASE_CONTENT
\"\"\"
    - artifact_paths:
      - summaries: ${artifact_paths[summaries]}
      - debug: ${artifact_paths[debug]}

    Execute this phase and return:
    IMPLEMENTATION_COMPLETE: 1
    summary_path: /path/to/summary
    work_remaining: 0
  "
}
```

### Lean-Specific Output Parsing

The `lean-implementer` returns extended IMPLEMENTATION_COMPLETE signal:

```yaml
IMPLEMENTATION_COMPLETE: 1
summary_path: /topic/summaries/002-proof-summary.md
theorems_proven: ["add_comm", "mul_comm"]
theorems_partial: ["complex_theorem"]
tactics_used: ["exact", "rw", "simp"]
mathlib_theorems: ["Nat.add_comm", "Nat.mul_comm"]
diagnostics: []
```

Parse these additional fields for aggregated reporting:

```bash
# Extract Lean-specific fields (if present)
THEOREMS_PROVEN=$(parse_output_field "theorems_proven")
TACTICS_USED=$(parse_output_field "tactics_used")

# Add to wave summary
if [ -n "$THEOREMS_PROVEN" ]; then
  echo "Theorems proven: $THEOREMS_PROVEN"
fi
```
```

#### Phase 3: Testing & Validation (30 minutes)

**Test Plan**: Create `.claude/specs/026_lean_command_orchestrator_implementation/plans/001-test-lean-implementer.md`

```markdown
### Phase 1: Basic Theorem Proving [NOT STARTED]
- [ ] Create Test.lean with add_comm theorem stub
- [ ] Prove add_comm using Nat.add_comm
- [ ] Verify proof compiles without sorry

### Phase 2: Mathlib Integration [NOT STARTED]
- [ ] Prove mul_comm using Mathlib
- [ ] Document theorems used in summary

### Phase 3: Error Handling [NOT STARTED]
- [ ] Test rate limit handling (3 requests/30s)
- [ ] Test proof failure recovery (invalid tactic)
- [ ] Verify TODO comment generation
```

**Test Execution**:

```bash
# Create test Lean file
cat > ~/lean-test-project/Test.lean <<'EOF'
theorem add_comm (a b : Nat) : a + b = b + a := by
  sorry

theorem mul_comm (a b : Nat) : a * b = b * a := by
  sorry
EOF

# Run /implement with test plan
/implement .claude/specs/026_lean_command_orchestrator_implementation/plans/001-test-lean-implementer.md

# Verify:
# 1. lean-implementer was invoked (check logs for "lean-implementer.md")
# 2. Proofs were completed (no sorry in Test.lean)
# 3. Summary created in summaries/ directory with Lean-specific fields
```

**Expected Output**:

```bash
=== Implementation-Only Workflow ===

Plan: .claude/specs/026_lean_command_orchestrator_implementation/plans/001-test-lean-implementer.md
Starting Phase: 1

╔═══════════════════════════════════════════════════════╗
║ WAVE-BASED IMPLEMENTATION PLAN            ║
╠═══════════════════════════════════════════════════════╣
║ Total Phases: 3                     ║
║ Waves: 3 (all sequential)               ║
║ Parallel Phases: 0                   ║
╚═══════════════════════════════════════════════════════╝

Wave 1: Phase 1 (Lean proof development)
  PROGRESS: Analyzing proof goals in Test.lean
  PROGRESS: Found 1 unproven theorem (add_comm)
  PROGRESS: Searching Mathlib for commutativity
  PROGRESS: Found Nat.add_comm, applying tactic
  PROGRESS: Proof complete ✓

Wave 2: Phase 2 (Lean proof development)
  PROGRESS: Found 1 unproven theorem (mul_comm)
  PROGRESS: Applying Nat.mul_comm
  PROGRESS: Proof complete ✓

Wave 3: Phase 3 (Lean proof development)
  (Error handling tests - pass)

╔═══════════════════════════════════════════════════════╗
║ IMPLEMENTATION COMPLETE               ║
╠═══════════════════════════════════════════════════════╣
║ Summary: 3 phases complete              ║
║ Theorems Proven: add_comm, mul_comm         ║
║ Tactics Used: exact (2x)               ║
║ Mathlib Theorems: Nat.add_comm, Nat.mul_comm    ║
╠═══════════════════════════════════════════════════════╣
║ Artifacts:                      ║
║ └─ Summary: summaries/001-proof-summary.md    ║
╠═══════════════════════════════════════════════════════╣
║ Next Steps:                      ║
║ 1. Review proofs in Test.lean            ║
║ 2. Run /test to verify compilation          ║
╚═══════════════════════════════════════════════════════╝
```

#### Phase 4: Documentation (30 minutes)

**Update Files**:

1. **`.claude/agents/README.md`** - Add lean-implementer entry:

```markdown
### lean-implementer
- **Model**: sonnet-4.5
- **Purpose**: AI-assisted Lean 4 theorem proving and formalization
- **Used By**: implementer-coordinator (auto-routing when .lean files detected)
- **Input**: Phase plan with Lean theorem stubs
- **Output**: Completed proofs with summaries
- **Key Features**: MCP tool integration, Mathlib search, tactic exploration
```

2. **`.claude/docs/guides/commands/implement-command-guide.md`** - Add Lean support note (Line 24):

```markdown
### What /implement Does
- Executes implementation phases from a plan
- Writes code according to plan specifications
- **Automatically detects Lean files and uses lean-implementer agent**
- Writes tests during Testing phases (but does NOT execute them)
...
```

3. **`.claude/specs/026_lean_command_orchestrator_implementation/summaries/001-implementation-summary.md`** - Create implementation summary

```markdown
# Lean Command Orchestrator Implementation Summary

## Metadata
- **Date**: 2025-12-02
- **Spec**: 026_lean_command_orchestrator_implementation
- **Implementation Approach**: Option B (lean-implementer agent with auto-routing)
- **Status**: ✅ Complete

## Implementation

### Phase 1: lean-implementer Agent
- Created `.claude/agents/lean-implementer.md` (300 lines)
- Implemented 8-step proof workflow (goal analysis → theorem search → tactic application → verification)
- Integrated lean-lsp-mcp tools (lean_goal, lean_leansearch, lean_loogle, lean_multi_attempt, lean_build)
- Error handling (rate limits, proof failures, diagnostic parsing)

### Phase 2: implementer-coordinator Enhancement
- Added Lean detection logic (grep for \.lean\b in phase tasks)
- Auto-routing to lean-implementer when Lean files detected
- Lean-specific output parsing (theorems_proven, tactics_used, mathlib_theorems)

### Phase 3: Testing
- Test plan created with 3 phases (basic proving, Mathlib integration, error handling)
- All tests passed ✓

### Phase 4: Documentation
- Updated agents/README.md with lean-implementer entry
- Updated implement-command-guide.md with auto-Lean support note
- Created implementation summary

## Artifacts

- Agent: `.claude/agents/lean-implementer.md`
- Test Plan: `.claude/specs/026_lean_command_orchestrator_implementation/plans/001-test-lean-implementer.md`
- Summary: `.claude/specs/026_lean_command_orchestrator_implementation/summaries/001-implementation-summary.md`

## Next Steps

1. Test with real ProofChecker theorems (TM logic proofs)
2. Measure performance on complex formalization tasks
3. Evaluate need for /lean command wrapper (Phase 2 of Hybrid Approach)
```

## Recommendations

### Primary Recommendation: Implement Option B (Hybrid Approach Phase 1)

**Rationale**:
1. **Maximizes Code Reuse**: Leverages existing /implement infrastructure (5-block structure, iteration management, state machine, checkpoint system)
2. **Minimizes Maintenance**: Only one new agent (lean-implementer), not a full command + coordinator
3. **Zero Learning Curve**: Users continue using /implement with Lean plans
4. **Future-Proof**: Auto-routing ensures Lean support in all workflows (including future commands)
5. **Proven Architecture**: implementer-coordinator → implementation-executor pattern already battle-tested

**Implementation Effort**: 2.5-3.5 hours (vs 3-5 hours for standalone /lean)

**Quality**: High (follows all .claude/ standards automatically via inheritance from /implement)

### Optional Enhancement: Add /lean Command Wrapper (Hybrid Phase 2)

**Condition**: Only implement if Lean-specific features become essential after testing Phase 1

**Lean-Specific Features**:
- `--prove-all` flag (batch all theorems in file)
- `--verify` mode (check existing proofs without modification)
- Lean-specific summary format (theorem statistics dashboard)

**Implementation Effort**: 1-2 hours (delegates to /implement internally, minimal code)

### Alternative: Standalone /lean Command (Not Recommended)

**Only Use If**:
- Lean workflow diverges significantly from general implementation (unlikely)
- Need for Lean-specific state machine transitions (not anticipated)
- Performance optimization requires Lean-only orchestration (premature)

**Risk**: Code duplication, maintenance burden, architectural fragmentation

## References

### Project Documentation
- `.claude/commands/implement.md` (Lines 1-850) - /implement command structure
- `.claude/agents/implementer-coordinator.md` (Lines 1-200) - Wave-based orchestration
- `.claude/docs/guides/commands/implement-command-guide.md` (Lines 1-200) - Implementation workflow
- `.claude/specs/025_lean_mcp_command_orchestration_strategy/reports/001-lean-mcp-command-integration.md` (Lines 1-964) - MCP integration status

### Lean Development Standards
- `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/Development/LEAN_STYLE_GUIDE.md` (Lines 1-484) - Coding conventions
- `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/Development/METAPROGRAMMING_GUIDE.md` (Lines 1-730) - Tactic metaprogramming
- `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/Documentation/Development/TACTIC_DEVELOPMENT.md` (Lines 1-738) - Tactic patterns and Aesop integration

### Claude Code Standards
- `.claude/docs/reference/standards/code-standards.md` - Bash sourcing, Task invocation patterns
- `.claude/docs/reference/standards/command-authoring.md` - Command development patterns
- `.claude/docs/reference/standards/output-formatting.md` - Console summary format
- `.claude/docs/concepts/hierarchical-agents-overview.md` - Agent architecture patterns

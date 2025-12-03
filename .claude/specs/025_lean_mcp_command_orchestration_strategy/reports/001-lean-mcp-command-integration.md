# Lean MCP Command Orchestration Strategy Research Report

**Date**: 2025-12-02
**Research Complexity**: 2 (Medium)
**Research Topic**: Lean-lsp-mcp command integration strategies for AI-assisted Lean theorem proving
**Target Environment**: NixOS + Neovim 0.11+ + Claude Code + MCP Hub + lean.nvim

---

## Executive Summary

This report evaluates strategies for integrating the lean-lsp-mcp Model Context Protocol server into your Claude Code workflow. After analyzing your existing orchestrator commands (`/build`, `/implement`) and agent architecture, **three viable approaches** emerge:

1. **Option A: Direct MCP Tool Access** (Recommended for immediate use)
2. **Option B: Lean-Specific Orchestrator Command** (Best for dedicated Lean development)
3. **Option C: Lean-Specialist Agent Pattern** (Most flexible, reusable across workflows)

The analysis reveals that **Option B** (dedicated `/lean` command) provides the best balance of usability, maintainability, and integration with your existing workflow patterns, while **Option C** (lean-specialist agent) offers superior long-term flexibility for incorporating Lean proving into multi-workflow scenarios.

---

## Research Findings

### 1. Current State: lean-lsp-mcp Integration

Based on previous implementation (Spec 022), lean-lsp-mcp is:

**Status**: ✅ **OPERATIONAL**
- MCP server installed and configured in `~/lean-test-project/.mcp.json`
- 17 tools available via stdio transport
- Neovim integration with `<leader>ri` keybinding for infoview toggle
- Integration tested and validated (automated tests passing)

**Available MCP Tools** (17 total):

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

---

### 2. Analysis of Existing Orchestrator Patterns

Your codebase demonstrates two primary orchestrator command patterns:

#### Pattern 1: `/build` - Full-Implementation Workflow

**Architecture**:
```
/build
├─ Block 1a: Setup & State Initialization
├─ Block 1b: implementer-coordinator invocation [HARD BARRIER]
│   └─ Delegates to: implementation-executor (via Task tool)
├─ Block 1c: Implementation verification
├─ Block 2:  test-executor invocation → Testing Phase
└─ Block 4:  Completion & Summary
```

**Key Characteristics**:
- **State machine-driven**: Uses workflow-state-machine.sh for transitions
- **Hard barrier pattern**: Enforces subagent delegation (cannot bypass)
- **Iteration support**: Multi-iteration context management via checkpoints
- **Test integration**: Automatic test execution with pass/fail branching
- **Terminal state**: `complete` (after all phases)

**Workflow Type**: `full-implementation`

**Relevant to Lean**: The hard barrier pattern ensures implementer-coordinator handles proof implementation, which could be adapted for lean-specialist delegation.

#### Pattern 2: `/implement` - Implementation-Only Workflow

**Architecture**:
```
/implement
├─ Block 1a: Setup & State Initialization
├─ Block 1b: implementer-coordinator invocation [HARD BARRIER]
│   └─ Delegates to: implementation-executor (via Task tool)
├─ Block 1c: Implementation verification & iteration check
├─ Block 1d: Phase marker validation
└─ Block 2:  Completion (no testing phase)
```

**Key Characteristics**:
- **Test-writing only**: Writes tests but doesn't execute them
- **Terminal state**: `$STATE_IMPLEMENT` (can transition to `complete`)
- **Iteration loop**: Supports multi-iteration for large plans
- **Summary requirement**: Testing Strategy section mandatory in output
- **Next step guidance**: Recommends `/test` command for test execution

**Workflow Type**: `implement-only`

**Relevant to Lean**: The implement-only pattern with `/test` follow-up mirrors a potential `/lean` → `/test` workflow for proof development.

---

### 3. Agent Architecture Patterns

Your agent system uses **hierarchical delegation** with specialized agents:

#### Existing Specialist Agents

**research-specialist** (Sonnet 4.5):
- Deep codebase analysis
- Technology investigation
- Report generation in `specs/reports/{topic}/`
- Used by: `/plan`, `/research`, `/revise`, `/debug`

**implementer-coordinator** (Haiku 4.5):
- Wave-based parallel phase execution
- Dependency analysis (Kahn's algorithm)
- Progress monitoring and aggregation
- Used by: `/build`, `/implement`

**implementation-executor** (Sonnet 4.5):
- Single phase task execution
- Progress tracking via checkbox-utils
- Git commit creation
- Invokes: spec-updater

**debug-analyst** (Sonnet 4.5):
- Parallel hypothesis testing
- Root cause identification
- Used by: `/debug`, `/build`

**Agent Communication Protocol**:

**Input Contract** (Hard Barrier Pattern):
```yaml
plan_path: /absolute/path/to/plan.md
topic_path: /absolute/path/to/topic/
summaries_dir: /topic/summaries/
artifact_paths:
  reports: /topic/reports/
  plans: /topic/plans/
  summaries: /topic/summaries/
  debug: /topic/debug/
```

**Output Signal** (IMPLEMENTATION_COMPLETE example):
```yaml
IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
plan_file: /path/to/plan
topic_path: /path/to/topic
summary_path: /path/to/summary
work_remaining: 0 or ["Phase 4", "Phase 5"]
context_exhausted: true|false
context_usage_percent: 85%
checkpoint_path: /path/to/checkpoint (if created)
requires_continuation: true|false
stuck_detected: true|false
```

**Agent Invocation Pattern** (from `/implement` Block 1b):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration 1/5)"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract (Hard Barrier Pattern)**:
    - plan_path: $PLAN_FILE
    - topic_path: $TOPIC_PATH
    - summaries_dir: ${TOPIC_PATH}/summaries/
    ...

    Execute all implementation phases according to the plan.

    Return: IMPLEMENTATION_COMPLETE: {PHASE_COUNT}
    plan_file: $PLAN_FILE
    summary_path: /path/to/summary
    work_remaining: 0 or list
    ...
  "
}
```

**Relevant to Lean**: This pattern provides a template for creating a `lean-specialist` agent that follows behavioral guidelines and returns structured output.

---

### 4. Lean-Specific Workflow Requirements

Based on lean-lsp-mcp capabilities and typical theorem proving workflows:

#### Proof Development Cycle

**Traditional Workflow** (manual):
1. Write theorem statement stub
2. Inspect proof goals (`:Lean Goal`)
3. Search Mathlib for applicable theorems (manual web search)
4. Apply tactics
5. Check diagnostics for errors
6. Iterate until `sorry` is eliminated

**AI-Assisted Workflow** (with lean-lsp-mcp):
1. Write theorem statement stub
2. Ask Claude: "Help me prove theorem X"
3. Claude uses MCP tools:
   - `lean_goal` - Check current proof state
   - `lean_leansearch` / `lean_loogle` - Find applicable theorems
   - `lean_hover_info` - Verify types match
   - `lean_multi_attempt` - Test multiple proof strategies
4. Claude suggests tactics with reasoning
5. User applies suggestions
6. Repeat until proof complete

#### Key Differences from General Implementation

**Lean Theorem Proving** vs **General Code Implementation**:

| Aspect | General Code | Lean Proofs |
|--------|-------------|-------------|
| **Goal** | Feature implementation | Proof completion |
| **Success Criteria** | Tests pass | No `sorry`, `#check` succeeds |
| **Iteration** | Multi-phase (files, modules) | Single theorem (tactics) |
| **Search** | Documentation, examples | Theorem libraries (Mathlib) |
| **Validation** | Test suite execution | Type checker, compiler |
| **Tools** | Compiler, linter, tests | LSP, goal inspection, library search |
| **Context** | Codebase architecture | Proof state, available theorems |

**Critical Insight**: Lean proof development is **tactic-level iteration** (fine-grained) rather than **phase-level iteration** (coarse-grained). This suggests a lean-specialist agent should:
- Work at **single theorem granularity** (not multi-phase plans)
- Use **proof state inspection** as primary feedback
- Employ **multi-attempt screening** for tactic exploration
- Provide **reasoning explanations** for tactic choices

---

### 5. Option A: Direct MCP Tool Access (Current State)

**Description**: Use Claude Code directly with lean-lsp-mcp tools via existing MCP Hub integration.

**How It Works**:
1. User opens `.lean` file in Neovim
2. User invokes Claude Code: `<leader>a` (Avante) or `:Claude`
3. User asks: "Help me prove theorem X"
4. Claude accesses lean-lsp-mcp tools automatically
5. Claude provides proof suggestions with reasoning

**Advantages**:
- ✅ **Already Operational**: No additional development needed
- ✅ **Minimal Learning Curve**: Natural language interaction
- ✅ **Full Tool Access**: Claude can use all 17 MCP tools
- ✅ **Flexible Context**: User can provide arbitrary context
- ✅ **No Workflow Overhead**: No plan files, no orchestration

**Disadvantages**:
- ❌ **No Progress Tracking**: No TODO.md integration
- ❌ **No Artifact Management**: No summaries or reports
- ❌ **Context Fragmentation**: No persistent state across sessions
- ❌ **No Reproducibility**: Conversational history not saved
- ❌ **Limited Batch Processing**: One theorem at a time
- ❌ **No Quality Gates**: No validation beyond manual review

**Use Cases**:
- Quick proof assistance for single theorems
- Exploratory theorem proving
- Learning Lean tactics and patterns
- Ad-hoc proof debugging

**Example Workflow**:
```lean
-- User writes theorem stub
theorem add_comm (a b : Nat) : a + b = b + a := by
  sorry

-- User invokes Claude Code (<leader>a)
-- User: "Help me prove add_comm using Mathlib"

-- Claude response:
-- "I'll search for commutativity theorems in Mathlib.
--  [Uses lean_leansearch("natural number addition commutativity")]
--  [Uses lean_hover_info on Nat.add_comm]
--
--  Replace `sorry` with: exact Nat.add_comm a b
--
--  Reasoning: Mathlib provides Nat.add_comm which states ∀ n m, n + m = m + n"
```

**Recommendation**: ✅ **Use for immediate needs** - This is your current working solution. Continue using for ad-hoc proof assistance while evaluating Options B/C for more structured workflows.

---

### 6. Option B: Lean-Specific Orchestrator Command (`/lean`)

**Description**: Create a dedicated `/lean` command similar to `/build` or `/implement`, with a lean-specialist subagent for theorem proving orchestration.

**Architecture**:

```
/lean [plan-file | theorem-name] [--prove | --verify]
├─ Block 1a: Setup & Lean Project Detection
│   ├─ Verify Lean 4 project (lakefile.toml)
│   ├─ Detect MCP server availability
│   ├─ Load plan or identify theorem target
│   └─ Initialize workflow state
├─ Block 1b: lean-specialist invocation [HARD BARRIER]
│   └─ Delegates to: lean-specialist agent
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

**lean-specialist Agent** (Proposed):

**Frontmatter**:
```yaml
---
allowed-tools: Read, Edit, Bash, Task
description: AI-assisted Lean 4 theorem proving specialist
model: sonnet-4.5
---
```

**Core Capabilities**:
1. **Proof Goal Analysis**
   - Extract proof goals via `lean_goal` MCP tool
   - Identify goal type, hypotheses, target
   - Assess proof complexity

2. **Theorem Discovery**
   - Search Mathlib via `lean_leansearch` (natural language)
   - Type-based search via `lean_loogle`
   - State-based search via `lean_state_search`
   - Local project search via `lean_local_search`

3. **Tactic Exploration**
   - Generate candidate tactics based on goal type
   - Use `lean_multi_attempt` to test multiple approaches
   - Evaluate which tactics make progress

4. **Proof Completion**
   - Apply successful tactics via Edit tool
   - Verify proof compiles (no `sorry`)
   - Check diagnostics for errors
   - Iterate until proof complete

5. **Documentation**
   - Explain tactic choices with reasoning
   - Link to Mathlib theorems used
   - Create proof summary artifact

**Input Contract**:
```yaml
theorem_target: "theorem_name" or "all_unproven"
lean_file_path: /absolute/path/to/file.lean
plan_path: /path/to/plan.md (optional)
topic_path: /path/to/topic/ (optional)
summaries_dir: /topic/summaries/
max_attempts: 3
```

**Output Signal**:
```yaml
PROOF_COMPLETE:
  theorem_name: "add_comm"
  status: complete|partial|failed
  tactics_used: ["exact Nat.add_comm a b"]
  theorems_applied: ["Nat.add_comm"]
  proof_summary_path: /topic/summaries/001-proof-summary.md
  diagnostics: []
  attempts: 2
```

**Command Usage Examples**:

```bash
# Prove specific theorem in file
/lean MyFile.lean add_comm

# Prove all unproven theorems in file
/lean MyFile.lean --prove-all

# Execute Lean plan (multi-theorem batch)
/lean .claude/specs/123_lean_formalization/plans/001-formalize-group-theory.md

# Verify existing proofs
/lean MyFile.lean --verify
```

**Advantages**:
- ✅ **Workflow Integration**: Compatible with `/plan` → `/lean` → `/test` pattern
- ✅ **Progress Tracking**: Integrates with TODO.md via plan files
- ✅ **Artifact Management**: Creates summaries in `specs/{topic}/summaries/`
- ✅ **Reproducibility**: Plan-based execution is repeatable
- ✅ **Batch Processing**: Can prove multiple theorems sequentially
- ✅ **Quality Gates**: Verification via diagnostics and `#check`
- ✅ **State Persistence**: Checkpoint support for large formalization projects

**Disadvantages**:
- ❌ **Development Overhead**: Requires creating command + agent (2-4 hours)
- ❌ **Learning Curve**: Users must learn `/lean` command syntax
- ❌ **Plan File Requirement**: Batch mode requires creating plans first
- ❌ **Maintenance Burden**: Another command to maintain alongside others

**Integration with Existing Workflows**:

**Scenario 1: Lean Formalization Project**
```bash
# Research Lean libraries
/research "Survey Mathlib group theory formalization patterns"

# Create formalization plan
/plan "Formalize basic group theory definitions and proofs"

# Execute Lean-specific implementation
/lean .claude/specs/123_lean_group/plans/001-group-theory-plan.md

# Update TODO.md
/todo
```

**Scenario 2: Single Theorem Proving**
```bash
# Direct invocation (no plan needed)
/lean MyTheorems.lean my_custom_theorem

# Claude creates proof summary in default location
# User can later run /todo to track completion
```

**Implementation Effort**:

**Phase 1: Command Creation** (1-2 hours)
- Create `/lean` command file following `/implement` pattern
- Argument parsing (theorem name, file path, flags)
- Lean project detection (lakefile.toml validation)
- MCP server availability check
- Workflow state initialization

**Phase 2: lean-specialist Agent** (1-2 hours)
- Create agent definition in `.claude/agents/lean-specialist.md`
- Define behavioral guidelines for proof development
- Implement MCP tool integration (lean_goal, lean_leansearch, etc.)
- Define output signal format (PROOF_COMPLETE)
- Create proof summary template

**Phase 3: Testing & Documentation** (1 hour)
- Test with sample theorems (add_comm, mul_comm, etc.)
- Create command guide: `.claude/docs/guides/commands/lean-command-guide.md`
- Add to command reference documentation
- Update TODO.md with implementation status

**Total Effort**: 3-5 hours

**Recommendation**: ✅ **Best for dedicated Lean development** - If you plan to spend significant time on Lean formalization projects (multiple theorems, structured proofs), this provides the most comprehensive workflow integration.

---

### 7. Option C: Lean-Specialist Agent Pattern (Reusable Across Workflows)

**Description**: Create a reusable `lean-specialist` agent that can be invoked from **any** command (`/implement`, `/build`, `/debug`) when Lean-specific work is detected.

**Architecture**:

```
Generic Workflow Command (/implement, /build, /debug)
├─ Detects Lean file in plan phases
├─ Invokes lean-specialist agent (instead of implementation-executor)
│   └─ lean-specialist follows behavioral guidelines
│       ├─ Proof development workflow
│       ├─ MCP tool usage (lean_goal, lean_leansearch, etc.)
│       └─ Returns: IMPLEMENTATION_COMPLETE (standard format)
└─ Continues with standard workflow phases
```

**How It Works**:

**Detection Logic** (in implementer-coordinator or implementation-executor):
```bash
# Detect Lean files in phase
if grep -qE '\.lean$' "$PHASE_TASKS"; then
  AGENT="lean-specialist"
else
  AGENT="implementation-executor"
fi

# Invoke appropriate agent
Task {
  subagent_type: "general-purpose"
  description: "Execute Lean proof development (Phase $PHASE_NUM)"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/${AGENT}.md
    ...
  "
}
```

**lean-specialist Agent** (Same as Option B):
- Proof goal analysis
- Theorem discovery via MCP tools
- Tactic exploration and application
- Proof verification
- Summary generation

**Key Difference from Option B**:
- **No dedicated `/lean` command** - Instead, lean-specialist is invoked automatically when Lean work is detected in **any** workflow
- **Standard output format** - Returns `IMPLEMENTATION_COMPLETE` signal (same as implementation-executor)
- **Seamless integration** - Works with `/implement`, `/build`, `/debug` without modifications

**Advantages**:
- ✅ **Workflow Agnostic**: Works with all orchestrator commands
- ✅ **No New Commands**: Reuses existing workflow infrastructure
- ✅ **Zero Learning Curve**: Users continue using `/implement` or `/build`
- ✅ **Automatic Detection**: No need to specify "this is Lean work"
- ✅ **Future-Proof**: New commands automatically support Lean
- ✅ **Minimal Maintenance**: Single agent definition, no command changes

**Disadvantages**:
- ❌ **Limited Lean-Specific Features**: No `--prove-all` or `--verify` flags
- ❌ **Detection Overhead**: Must detect Lean files in every phase
- ❌ **Generic Output Format**: No Lean-specific summary fields
- ❌ **No Direct Invocation**: Cannot call "just prove this theorem" without a plan

**Integration Example**:

**Scenario: Lean Formalization in `/implement` Workflow**

**Plan File** (`.claude/specs/123_lean_group/plans/001-group-theory-plan.md`):
```markdown
### Phase 1: Basic Definitions [NOT STARTED]
- [ ] Define `Group` typeclass in GroupTheory/Basic.lean
- [ ] Define `Subgroup` structure
- [ ] Prove `subgroup_closure_mem`

### Phase 2: Homomorphisms [NOT STARTED]
- [ ] Define `GroupHom` typeclass
- [ ] Prove `hom_preserves_identity`
- [ ] Prove `hom_preserves_inverse`
```

**User Invocation**:
```bash
/implement .claude/specs/123_lean_group/plans/001-group-theory-plan.md
```

**Execution Flow**:
1. `/implement` invokes `implementer-coordinator`
2. Coordinator detects `.lean` files in Phase 1 tasks
3. Coordinator invokes `lean-specialist` (instead of `implementation-executor`)
4. `lean-specialist` uses MCP tools to develop proofs
5. Returns `IMPLEMENTATION_COMPLETE` with standard format
6. `/implement` continues to Phase 2 (also detects Lean, uses lean-specialist)
7. All phases complete, summary created

**User Experience**: Identical to non-Lean workflows - just run `/implement` with a Lean plan.

**Implementation Effort**:

**Phase 1: lean-specialist Agent** (1-2 hours)
- Create agent definition (same as Option B)
- Ensure output format matches `IMPLEMENTATION_COMPLETE` standard

**Phase 2: Detection Logic** (1 hour)
- Add Lean file detection to `implementer-coordinator.md`
- Modify agent invocation to use `lean-specialist` when detected
- Test with sample Lean plan

**Phase 3: Documentation** (30 min)
- Update agent README with lean-specialist entry
- Add note to `/implement` command guide about automatic Lean support
- Create example Lean plan

**Total Effort**: 2.5-3.5 hours

**Recommendation**: ✅ **Best for long-term flexibility** - If you want Lean support across all workflows without creating specialized commands, this is the most sustainable approach. Lean work becomes a "first-class citizen" in your general development workflows.

---

## Comparative Analysis

### Decision Matrix

| Criterion | Option A: Direct MCP | Option B: `/lean` Command | Option C: Agent Pattern |
|-----------|---------------------|---------------------------|-------------------------|
| **Immediate Usability** | ✅✅✅ Ready now | ❌ Requires dev (3-5h) | ❌ Requires dev (2.5-3.5h) |
| **Workflow Integration** | ❌ None | ✅✅✅ Full integration | ✅✅ Reuses existing |
| **Progress Tracking** | ❌ None | ✅✅✅ TODO.md, plans | ✅✅ TODO.md, plans |
| **Artifact Management** | ❌ None | ✅✅✅ Summaries, reports | ✅✅ Summaries, reports |
| **Reproducibility** | ❌ Conversational only | ✅✅✅ Plan-based | ✅✅ Plan-based |
| **Batch Processing** | ❌ One theorem at a time | ✅✅✅ Multi-theorem | ✅✅ Multi-theorem |
| **Learning Curve** | ✅✅✅ Natural language | ❌ New command syntax | ✅✅✅ Existing commands |
| **Lean-Specific Features** | ❌ None | ✅✅✅ Flags, modes | ❌ Limited |
| **Maintenance Burden** | ✅✅✅ None | ❌ New command + agent | ✅✅ Agent only |
| **Future-Proof** | ✅ Stable | ❌ Command-specific | ✅✅✅ Workflow-agnostic |
| **Development Time** | ✅✅✅ 0 hours | ❌ 3-5 hours | ❌ 2.5-3.5 hours |

**Scoring Legend**:
- ✅✅✅ Excellent
- ✅✅ Good
- ✅ Acceptable
- ❌ Poor

### Recommended Approach

**Phased Implementation**:

**Phase 1: Immediate Use** (0 hours)
→ **Option A**: Use direct MCP tool access for ad-hoc proof assistance
- Already operational, no development needed
- Covers 80% of quick theorem proving scenarios
- Natural language interaction, minimal friction

**Phase 2: Structured Workflows** (2.5-3.5 hours)
→ **Option C**: Implement lean-specialist agent pattern
- Provides workflow integration without command proliferation
- Reuses existing `/implement` and `/build` infrastructure
- Enables batch formalization projects with progress tracking
- Works seamlessly with `/plan` → `/implement` → `/test` pattern

**Phase 3: Advanced Features** (Optional, 1-2 hours)
→ **Option B Enhancement**: Add `/lean` command if needed
- Only if Lean-specific flags (`--prove-all`, `--verify`) become essential
- Can delegate to lean-specialist agent internally (code reuse)
- Provides dedicated Lean workflow for power users

**Why This Sequence**:
1. **Minimize Upfront Investment**: Start with what works (Option A)
2. **Maximize Reusability**: Option C integrates Lean into general workflows
3. **Defer Specialization**: Only create `/lean` if generic workflows prove insufficient

---

## Implementation Recommendations

### Immediate Action: Option A (Current State)

**Next Steps** (0 hours):
1. ✅ **Verify MCP Connection**: Run `/mcp` in Claude Code to confirm lean-lsp server listed
2. ✅ **Test Proof Assistance**: Open a `.lean` file, invoke Claude, ask for theorem help
3. ✅ **Document Workflow**: Create personal notes on effective prompts for Lean proving
4. ✅ **Identify Gaps**: Note scenarios where conversational approach feels inadequate

**Example Prompts to Try**:
```
"Help me prove theorem add_comm using Mathlib"
"Search for commutativity theorems applicable to natural numbers"
"Inspect the proof goal at line 42, column 10"
"Test multiple tactics for proving associativity of addition"
"Explain why tactic 'ring' works for this goal"
```

### Medium-Term: Option C Implementation (2.5-3.5 hours)

**Implementation Plan**:

**Phase 1: Create lean-specialist Agent** (1.5-2 hours)

**File**: `.claude/agents/lean-specialist.md`

**Frontmatter**:
```yaml
---
allowed-tools: Read, Edit, Bash
description: AI-assisted Lean 4 theorem proving and formalization specialist
model: sonnet-4.5
---
```

**Content Sections**:
1. **Core Capabilities**
   - Proof goal analysis via `lean_goal` MCP tool
   - Theorem search (lean_leansearch, lean_loogle, lean_state_search)
   - Tactic exploration via `lean_multi_attempt`
   - Proof verification and diagnostics

2. **MCP Tool Usage Patterns**
   - Tool invocation syntax (via Bash tool with uvx commands)
   - Rate limit management (3 requests/30s for external tools)
   - Fallback to local search when rate limited

3. **Proof Development Workflow**
   - STEP 1: Identify unproven theorems (grep for `sorry`)
   - STEP 2: Extract proof goals (lean_goal at theorem location)
   - STEP 3: Search applicable theorems (lean_leansearch, lean_loogle)
   - STEP 4: Generate candidate tactics
   - STEP 5: Test tactics (lean_multi_attempt)
   - STEP 6: Apply successful tactics (Edit tool)
   - STEP 7: Verify proof (lean_diagnostic_messages)
   - STEP 8: Iterate until no `sorry` remains

4. **Output Signal Format**
   ```yaml
   IMPLEMENTATION_COMPLETE: {THEOREM_COUNT}
   plan_file: /path/to/plan
   topic_path: /path/to/topic
   summary_path: /path/to/summary
   theorems_proven: ["add_comm", "mul_comm"]
   theorems_partial: []
   theorems_failed: []
   tactics_used: ["exact", "rw", "simp"]
   diagnostics: []
   ```

5. **Standards Compliance**
   - Use checkbox-utils.sh for progress tracking
   - Create summaries in `summaries/` directory
   - Link to plan file in summary metadata
   - Follow error-handling patterns

**Phase 2: Modify implementer-coordinator** (30 min)

**File**: `.claude/agents/implementer-coordinator.md`

**Add Lean Detection Section**:
```markdown
## Lean File Detection (Auto-Routing)

When a phase contains `.lean` files, delegate to lean-specialist instead of implementation-executor:

**Detection Logic**:
```bash
# Check if phase tasks mention Lean files
if grep -qE '\.lean\b' <<< "$PHASE_TASKS"; then
  EXECUTOR_AGENT="lean-specialist"
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

**Phase 3: Testing & Validation** (30 min)

**Test Plan** (create `.claude/specs/025_lean_mcp/plans/test-lean-specialist.md`):
```markdown
### Phase 1: Basic Theorem Proving [NOT STARTED]
- [ ] Prove theorem add_comm in Test.lean
- [ ] Verify proof compiles without sorry

### Phase 2: Mathlib Integration [NOT STARTED]
- [ ] Prove theorem mul_comm using Mathlib
- [ ] Document theorems used
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
/implement .claude/specs/025_lean_mcp/plans/test-lean-specialist.md

# Verify:
# 1. lean-specialist was invoked (check logs)
# 2. Proofs were completed (no sorry in Test.lean)
# 3. Summary created in summaries/ directory
```

**Phase 4: Documentation** (30 min)

**Update Files**:
1. `.claude/agents/README.md` - Add lean-specialist entry to "Available Agents" section
2. `.claude/docs/guides/commands/implement-command-guide.md` - Add note about automatic Lean support
3. `.claude/specs/025_lean_mcp/summaries/lean-specialist-implementation-summary.md` - Document implementation

**Total Time**: 2.5-3.5 hours

### Long-Term: Option B Enhancement (Optional, 1-2 hours)

**Only implement if**:
- You frequently need `--prove-all` flag (batch all theorems in file)
- You want `--verify` mode (check existing proofs without modification)
- You need Lean-specific summary format (theorem statistics, tactic usage metrics)

**Implementation**:
- Create `/lean` command following `/implement` pattern
- Reuse lean-specialist agent (no duplication)
- Add Lean-specific flags and modes
- Update command reference documentation

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **MCP Server Crashes** | Low | Medium | LEAN_LOG_LEVEL=WARNING, monitor logs, restart on failure |
| **Rate Limit Throttling** | Medium | Medium | Prioritize lean_local_search, batch theorem queries, implement backoff |
| **Proof Verification Failures** | Medium | High | Multi-attempt screening, fallback to partial proofs, user review |
| **Context Exhaustion (Large Proofs)** | Medium | High | Iteration support (same as /implement), checkpoint at theorem boundaries |
| **Agent Output Format Drift** | Low | High | Strict output signal validation in verification block (hard barrier pattern) |
| **Lean Project Build Failures** | Medium | Medium | Pre-build validation (lake build), clear error messages, recovery instructions |

### Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **User Confusion (Multiple Options)** | High | Low | Clear documentation, phased rollout (A → C → B), decision tree in docs |
| **Maintenance Burden** | Low | Medium | Option C minimizes command proliferation, reuses existing infrastructure |
| **Documentation Drift** | Medium | Low | Standard agent documentation template, version control for behavioral guidelines |
| **Workflow Fragmentation** | Low | Medium | Option C ensures Lean works in all workflows (prevent siloing) |

---

## Success Criteria

### Option A (Direct MCP) Success Metrics

**Usability**:
- [ ] Claude provides relevant theorem suggestions within 10 seconds
- [ ] MCP tools return results without errors
- [ ] User can complete proof with ≤3 clarification questions

**Quality**:
- [ ] Suggested tactics compile without errors
- [ ] Theorems referenced exist in Mathlib
- [ ] Proof reasoning explanations are accurate

### Option C (Agent Pattern) Success Metrics

**Integration**:
- [ ] lean-specialist invoked automatically for Lean files
- [ ] Standard workflow commands (`/implement`, `/build`) work with Lean plans
- [ ] Progress tracking (checkboxes, summaries) works for Lean phases

**Functionality**:
- [ ] Agent completes proofs without `sorry` (90% success rate)
- [ ] Multi-theorem batch processing works (3+ theorems)
- [ ] Proof summaries link to plan files correctly

**Performance**:
- [ ] Proof completion time: ≤2 minutes per simple theorem
- [ ] Context usage: ≤70% for standard formalization tasks
- [ ] Rate limit compliance: No API errors from external search tools

### Option B (Dedicated Command) Success Metrics

**Feature Completeness**:
- [ ] `--prove-all` flag proves all theorems in file
- [ ] `--verify` flag checks existing proofs
- [ ] Summary includes Lean-specific statistics (tactics, theorems, diagnostics)

**Usability**:
- [ ] Command syntax clear and consistent with other orchestrators
- [ ] Help documentation complete and accurate
- [ ] Error messages actionable and specific

---

## Related Projects and Ecosystem

### Complementary Tools

**LeanTool** (Alternative Lean AI Integration):
- Repository: https://github.com/GasStationManager/LeanTool
- Approach: Direct Lean 4 interaction without MCP layer
- Use Case: Compare approaches if MCP overhead becomes problematic

**LeanExplore MCP** (Educational Lean Exploration):
- Website: https://www.leanexplore.com/docs/mcp
- Focus: Interactive Lean learning and exploration
- Use Case: Reference for MCP-based Lean tool design patterns

**Lean4 Theorem Proving Skill** (Claude Desktop):
- Repository: https://github.com/cameronfreer/lean4-skills
- Approach: Lean 4 skill for Claude Desktop
- Use Case: Study skill pattern for potential conversion to agent

### Reference Documentation

**Lean 4 Manual**: https://lean-lang.org/documentation/
**Mathlib Documentation**: https://leanprover-community.github.io/mathlib4_docs/
**MCP Specification**: https://modelcontextprotocol.io/
**lean-lsp-mcp GitHub**: https://github.com/oOo0oOo/lean-lsp-mcp

---

## Conclusion

**Recommended Strategy**: **Phased Implementation (A → C → B optional)**

**Phase 1: Immediate Use** (0 hours)
- Continue using **Option A** (direct MCP tool access) for ad-hoc theorem proving
- Already operational, covers most quick proof assistance scenarios
- Document effective prompts and common workflows

**Phase 2: Structured Integration** (2.5-3.5 hours)
- Implement **Option C** (lean-specialist agent pattern)
- Enables batch formalization with progress tracking
- Reuses existing `/implement` and `/build` infrastructure
- Provides workflow integration without command proliferation

**Phase 3: Advanced Features** (Optional, 1-2 hours)
- Add **Option B** (`/lean` command) only if Lean-specific features become essential
- Delegates to lean-specialist agent internally (code reuse)
- Provides dedicated workflow for power users

**Key Insights**:

1. **MCP Integration is Operational**: Spec 022 successfully connected lean-lsp-mcp. No additional infrastructure work needed.

2. **Lean Differs from General Code**: Theorem proving is tactic-level iteration (fine-grained) rather than phase-level iteration (coarse-grained). Agent design must reflect this.

3. **Workflow Reusability Wins**: Option C (agent pattern) provides the best balance of integration depth and maintenance burden by reusing existing orchestrator commands.

4. **Minimize Upfront Investment**: Start with Option A (already working), only implement Option C if batch formalization projects become common.

5. **Defer Specialization**: Only create `/lean` command (Option B) if generic workflows prove insufficient.

**Next Immediate Action**: Test Option A by asking Claude to help prove a simple theorem in your lean-test-project, then document the experience to inform Option C implementation decisions.

---

**Report Complete**
**Estimated Implementation Time** (Option C): 2.5-3.5 hours
**Recommended Starting Point**: Option A (Direct MCP Access) - 0 hours, already operational

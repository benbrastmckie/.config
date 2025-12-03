# Lean Command Orchestrator Implementation Plan

## Plan Metadata

- **Date**: 2025-12-02
- **Feature**: Dedicated `/lean` command orchestrator for AI-assisted Lean 4 theorem proving with lean-lsp-mcp integration
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Lean Command Orchestrator Design Research](/home/benjamin/.config/.claude/specs/026_lean_command_orchestrator_implementation/reports/001-lean-command-orchestrator-design.md)
- **Related Specifications**:
  - [Lean MCP Command Integration Strategy](/home/benjamin/.config/.claude/specs/025_lean_mcp_command_orchestration_strategy/reports/001-lean-mcp-command-integration.md)
  - Spec 022: lean-lsp-mcp Neovim Integration (operational)

## Overview

Implement a dedicated `/lean` command orchestrator following `/implement` command patterns, with specialized `lean-implementer` agent for AI-assisted Lean 4 theorem proving. The command integrates lean-lsp-mcp MCP server tools for proof goal inspection, theorem search, tactic exploration, and proof verification.

**Core Architecture**:
```
/lean [plan-file | lean-file] [--prove-all | --verify] [--max-attempts=N]
├─ Block 1a: Setup & Lean Project Detection
├─ Block 1b: lean-implementer invocation [HARD BARRIER]
│   └─ Uses lean-lsp-mcp tools (lean_goal, lean_leansearch, lean_multi_attempt, lean_build)
├─ Block 1c: Verification & Diagnostics
└─ Block 2: Completion & Summary
```

**Key Features**:
- Lean project validation (lakefile.toml, lakefile.lean detection)
- MCP server availability verification
- Plan-based batch proving (multi-theorem)
- Single-theorem proving (direct file invocation)
- Proof verification mode (`--verify`)
- Proof summary artifacts with tactic explanations

## Success Criteria

1. `/lean` command successfully proves simple theorems (e.g., `add_comm`, `mul_comm`)
2. MCP tools invoked correctly (lean_goal, lean_leansearch, lean_loogle)
3. Proof summaries created in `summaries/` directory with tactic reasoning
4. Diagnostics checked via `lean_diagnostic_messages` (no errors)
5. Integration with `/plan` → `/lean` → `/test` workflow
6. Follows all `.claude/` standards (command authoring, error logging, output formatting)

---

## Phase 0: Standards Compliance Verification [NOT STARTED]

**Duration**: 1 hour
**Dependencies**: None

Verify alignment with .claude/ system standards and document any necessary deviations.

### Tasks

- [ ] Review command authoring standards (`.claude/docs/reference/standards/command-authoring.md`)
  - Execution directive requirements (imperative instructions)
  - Task tool invocation patterns (no code block wrappers)
  - Subprocess isolation (library re-sourcing, set +H)
  - State persistence patterns (file-based communication)

- [ ] Review agent development standards (`.claude/docs/concepts/hierarchical-agents-overview.md`)
  - Frontmatter requirements (allowed-tools, model, model-justification)
  - Input contract specification (hard barrier pattern)
  - Output signal format (IMPLEMENTATION_COMPLETE extended for Lean)
  - Error handling protocols

- [ ] Review error logging integration (`.claude/docs/concepts/patterns/error-handling.md`)
  - Error-handling.sh library sourcing
  - Error log initialization (`ensure_error_log_exists`)
  - Error type taxonomy (state_error, validation_error, agent_error)
  - Error logging calls (`log_command_error`)

- [ ] Review output formatting standards (`.claude/docs/reference/standards/output-formatting.md`)
  - Output suppression patterns (`2>/dev/null` with error preservation)
  - Block consolidation targets (2-3 bash blocks per command)
  - Console summary format (4-section with emoji markers)
  - Comment standards (WHAT not WHY)

- [ ] Document alignment with Lean-specific standards
  - LEAN_STYLE_GUIDE.md naming conventions (snake_case functions, PascalCase types)
  - METAPROGRAMMING_GUIDE.md tactic patterns (goal management, proof construction)
  - TACTIC_DEVELOPMENT.md testing requirements (unit tests, negative tests)

- [ ] Identify any standard deviations and justification
  - Lean-specific output fields (theorems_proven, tactics_used)
  - MCP tool rate limit handling (3 requests/30s combined)
  - Proof-level iteration vs phase-level iteration

**Completion Criteria**:
- Standards compliance checklist completed
- No conflicts with existing .claude/ patterns
- Deviations documented with justifications

---

## Phase 1: Create lean-implementer Agent [NOT STARTED]

**Duration**: 3-4 hours
**Dependencies**: Phase 0

Implement specialized agent for Lean 4 theorem proving using lean-lsp-mcp tools.

### Tasks

- [ ] Create agent file `.claude/agents/lean-implementer.md`

- [ ] Implement frontmatter section
  ```yaml
  ---
  allowed-tools: Read, Edit, Bash
  description: AI-assisted Lean 4 theorem proving and formalization specialist
  model: sonnet-4.5
  model-justification: Complex proof search, tactic generation, Mathlib theorem discovery requiring deep reasoning
  fallback-model: sonnet-4.5
  ---
  ```

- [ ] Document core capabilities (8-step proof workflow)
  - STEP 1: Identify Unproven Theorems (grep for `sorry` markers)
  - STEP 2: Extract Proof Goals (`lean_goal` MCP tool)
  - STEP 3: Search Applicable Theorems (`lean_leansearch`, `lean_loogle`, `lean_state_search`)
  - STEP 4: Generate Candidate Tactics (pattern matching on goal structure)
  - STEP 5: Test Tactics (`lean_multi_attempt` multi-proof screening)
  - STEP 6: Apply Successful Tactics (Edit tool to replace `sorry`)
  - STEP 7: Verify Proof Completion (`lean_build`, `lean_diagnostic_messages`)
  - STEP 8: Create Proof Summary (summaries/ directory artifact)

- [ ] Define input contract (compatible with implementation-executor)
  ```yaml
  plan_path: /absolute/path/to/plan.md
  topic_path: /absolute/path/to/topic/
  phase_number: 2
  phase_content: "### Phase 2: Prove Commutativity\n- [ ] Prove add_comm..."
  artifact_paths:
    summaries: /topic/summaries/
    debug: /topic/debug/
  lean_file_path: /absolute/path/to/file.lean  # Lean-specific
  max_attempts: 3  # Lean-specific
  ```

- [ ] Define output signal (extended IMPLEMENTATION_COMPLETE)
  ```yaml
  IMPLEMENTATION_COMPLETE: 1
  plan_file: /path/to/plan.md
  topic_path: /path/to/topic
  summary_path: /topic/summaries/002-proof-summary.md
  work_remaining: 0
  theorems_proven: ["add_comm", "mul_comm"]  # Lean-specific
  theorems_partial: ["complex_theorem"]      # Lean-specific
  tactics_used: ["exact", "rw", "simp"]      # Lean-specific
  mathlib_theorems: ["Nat.add_comm"]         # Lean-specific
  diagnostics: []                             # Lean-specific
  ```

- [ ] Implement MCP tool integration patterns
  - Bash invocation syntax: `uvx --from lean-lsp-mcp lean-goal "$file" $line $col`
  - Error handling for MCP failures (server not running, file not found)
  - Rate limit management (3 requests/30s for external search tools)
  - Fallback to `lean_local_search` (no rate limit)

- [ ] Implement proof development workflow steps
  - STEP 1 implementation: Grep pattern for `sorry`, extract line numbers
  - STEP 2 implementation: Parse `lean_goal` JSON output, extract goal type and hypotheses
  - STEP 3 implementation: Natural language search (`lean_leansearch "commutativity"`), type-based search (`lean_loogle "Nat → Nat → Nat"`)
  - STEP 4 implementation: Pattern-based tactic generation (commutativity → `*_comm`, associativity → `*_assoc`)
  - STEP 5 implementation: JSON array formatting for `lean_multi_attempt`, parse success/failure
  - STEP 6 implementation: Edit tool with exact match for `sorry` replacement
  - STEP 7 implementation: Parse `lean_diagnostic_messages`, check for empty diagnostics array
  - STEP 8 implementation: Markdown summary template with theorem metadata, tactic reasoning, references

- [ ] Implement error handling protocols
  - MCP tool failures (server crashed, timeout)
  - Rate limit throttling (wait 30 seconds, retry)
  - Proof verification failures (diagnostics errors, backtrack to `sorry`)
  - No applicable theorems found (leave TODO comment)

- [ ] Implement progress reporting
  - Real-time markers: "PROGRESS: Analyzing proof goals", "PROGRESS: Found 3 unproven theorems"
  - Summary statistics: theorems_total, theorems_proven, theorems_partial, tactics_used

- [ ] Add example usage section
  - Single theorem proving example
  - Multi-theorem batch proving example
  - Proof verification example

- [ ] Add Lean standards references
  - LEAN_STYLE_GUIDE.md (naming conventions, formatting)
  - METAPROGRAMMING_GUIDE.md (tactic patterns)
  - TACTIC_DEVELOPMENT.md (testing requirements)

**Completion Criteria**:
- Agent file created at `.claude/agents/lean-implementer.md`
- All 8 proof workflow steps documented with implementation details
- Input/output contracts defined and compatible with coordinator pattern
- MCP tool integration patterns specified with error handling
- Example usage section with 3+ examples

---

## Phase 2: Create /lean Command [NOT STARTED]

**Duration**: 2-3 hours
**Dependencies**: Phase 1

Implement `/lean` command following `/implement` command patterns with Lean-specific argument parsing.

### Tasks

- [ ] Create command file `.claude/commands/lean.md`

- [ ] Implement frontmatter section
  ```yaml
  ---
  allowed-tools: Task, Bash, Read, Grep, Glob
  argument-hint: [plan-file | lean-file] [--prove-all | --verify] [--max-attempts=N]
  description: Lean theorem proving workflow with lean-lsp-mcp integration
  command-type: primary
  dependent-agents:
    - lean-implementer
  library-requirements:
    - workflow-state-machine.sh: ">=2.0.0"
    - state-persistence.sh: ">=1.5.0"
    - error-handling.sh: ">=1.0.0"
  documentation: See .claude/docs/guides/commands/lean-command-guide.md for usage
  ---
  ```

- [ ] Implement Block 1a: Setup & Lean Project Detection
  - 2-block argument capture pattern (TEMP_FILE → parsing)
  - Three-tier library sourcing (error-handling.sh → state-persistence.sh → workflow-state-machine.sh)
  - Lean project detection (check for `lakefile.toml` or `lakefile.lean`)
  - MCP server availability check (`uvx --from lean-lsp-mcp --help` exit code)
  - Argument parsing: `LEAN_FILE`, `MODE` (--prove-all, --verify), `MAX_ATTEMPTS`
  - State machine initialization (`sm_init`)
  - Error log initialization (`ensure_error_log_exists`)

- [ ] Implement Block 1b: lean-implementer Invocation [HARD BARRIER]
  - Summary output path calculation
  - Task tool invocation with input contract:
    ```markdown
    **EXECUTE NOW**: USE the Task tool to invoke lean-implementer.

    Task {
      subagent_type: "general-purpose"
      description: "Lean theorem proving for ${LEAN_FILE} with mandatory summary creation"
      prompt: "
        Read and follow ALL behavioral guidelines from:
        ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-implementer.md

        **Input Contract**:
        - lean_file_path: ${LEAN_FILE}
        - topic_path: ${TOPIC_PATH}
        - artifact_paths:
          - summaries: ${SUMMARIES_DIR}
          - debug: ${DEBUG_DIR}
        - max_attempts: ${MAX_ATTEMPTS}

        Execute proof development workflow.
        Return: IMPLEMENTATION_COMPLETE: 1
        summary_path: /path/to/summary
        theorems_proven: [...]
        diagnostics: []
      "
    }
    ```

- [ ] Implement Block 1c: Verification & Diagnostics
  - Summary file existence validation (≥100 bytes)
  - Parse output signal (IMPLEMENTATION_COMPLETE, theorems_proven, diagnostics)
  - Diagnostic validation (check for empty diagnostics array)
  - Proof completeness validation (no `sorry` in file)

- [ ] Implement Block 2: Completion & Summary
  - 4-section console summary:
    ```
    ╔═══════════════════════════════════════════════════════╗
    ║ LEAN THEOREM PROVING COMPLETE            ║
    ╠═══════════════════════════════════════════════════════╣
    ║ Summary: 3 theorems proven, 0 partial         ║
    ║ Theorems: add_comm, mul_comm, assoc_thm       ║
    ║ Tactics: exact (2x), rw (1x)             ║
    ║ Mathlib: Nat.add_comm, Nat.mul_comm         ║
    ╠═══════════════════════════════════════════════════════╣
    ║ Artifacts:                      ║
    ║ └─ Summary: summaries/001-proof-summary.md    ║
    ╠═══════════════════════════════════════════════════════╣
    ║ Next Steps:                      ║
    ║ 1. Review proofs in ${LEAN_FILE}         ║
    ║ 2. Run /test to verify compilation          ║
    ╚═══════════════════════════════════════════════════════╝
    ```
  - PROOF_COMPLETE signal emission
  - Checkpoint cleanup

- [ ] Implement error logging integration
  - Set workflow metadata: `COMMAND_NAME="/lean"`, `WORKFLOW_ID="lean_$(date +%s)"`
  - Log errors with `log_command_error` (validation_error, agent_error, execution_error)
  - Parse subagent errors with `parse_subagent_error`

- [ ] Add mode-specific logic
  - `--prove-all`: Prove all theorems with `sorry` in file
  - `--verify`: Check existing proofs without modification
  - Default: Prove all unproven theorems

**Completion Criteria**:
- Command file created at `.claude/commands/lean.md`
- All blocks implemented with imperative directives
- Hard barrier pattern enforced for Task invocation
- Error logging integrated throughout
- Console summary matches 4-section format

---

## Phase 3: Testing & Validation [NOT STARTED]

**Duration**: 2-3 hours
**Dependencies**: Phase 1, Phase 2

Create test suite and validate end-to-end workflow.

### Tasks

- [ ] Create test Lean file `~/lean-test-project/Test.lean`
  ```lean
  theorem add_comm (a b : Nat) : a + b = b + a := by
    sorry

  theorem mul_comm (a b : Nat) : a * b = b * a := by
    sorry

  theorem add_assoc (a b c : Nat) : a + (b + c) = (a + b) + c := by
    sorry
  ```

- [ ] Create test plan `.claude/specs/026_lean_command_orchestrator_implementation/plans/test-lean-command.md`
  ```markdown
  ### Phase 1: Basic Theorem Proving [NOT STARTED]
  - [ ] Prove add_comm using Nat.add_comm
  - [ ] Verify proof compiles without sorry

  ### Phase 2: Mathlib Integration [NOT STARTED]
  - [ ] Prove mul_comm using Mathlib
  - [ ] Document theorems used in summary

  ### Phase 3: Multi-Theorem Batch [NOT STARTED]
  - [ ] Prove add_assoc using Mathlib
  - [ ] Verify all proofs compile
  - [ ] Check summary statistics
  ```

- [ ] Execute test 1: Single theorem proving
  - Run: `/lean ~/lean-test-project/Test.lean` (default mode proves all)
  - Verify: `add_comm` proof replaced `sorry` with `exact Nat.add_comm a b`
  - Verify: Summary created in `summaries/001-proof-summary.md`
  - Verify: `theorems_proven: ["add_comm"]` in output

- [ ] Execute test 2: MCP tool integration
  - Verify: `lean_goal` invoked to extract proof goal
  - Verify: `lean_leansearch` invoked to find theorems
  - Verify: `lean_multi_attempt` invoked to test tactics (if multiple candidates)
  - Verify: `lean_build` invoked to verify compilation
  - Verify: `lean_diagnostic_messages` invoked to check errors

- [ ] Execute test 3: Proof verification mode
  - Run: `/lean ~/lean-test-project/Test.lean --verify`
  - Verify: No modifications to file (proofs unchanged)
  - Verify: Diagnostics checked and reported
  - Verify: Summary reports verification status

- [ ] Execute test 4: Error handling
  - Test MCP server unavailable (stop server, run command)
  - Verify: Error logged with `log_command_error`
  - Verify: Graceful failure with informative message

- [ ] Execute test 5: Rate limit handling
  - Invoke 4+ external search tools in rapid succession
  - Verify: Backoff triggered after 3 requests
  - Verify: Fallback to `lean_local_search`

- [ ] Execute test 6: Plan-based batch proving
  - Run: `/lean .claude/specs/026_lean_command_orchestrator_implementation/plans/test-lean-command.md`
  - Verify: All phases executed
  - Verify: All theorems proven
  - Verify: Summary aggregates all proofs

- [ ] Validate proof summaries
  - Check summary includes theorem name, file, status
  - Check summary includes proof strategy explanation
  - Check summary includes tactics used with reasoning
  - Check summary includes Mathlib theorems with references
  - Check summary includes diagnostics (should be empty)

- [ ] Run standards validators
  - Run: `bash .claude/scripts/validate-all-standards.sh --staged`
  - Verify: No ERROR-level violations
  - Fix any WARNING-level issues

- [ ] Performance benchmarking
  - Measure time for simple theorem (target: ≤2 minutes)
  - Measure time for complex theorem (target: ≤5 minutes)
  - Measure context usage (target: ≤70% for standard tasks)

**Completion Criteria**:
- All 6 test cases pass
- Proof summaries contain all required sections
- Standards validation passes (no ERRORs)
- Performance meets targets

---

## Phase 4: Documentation [NOT STARTED]

**Duration**: 1.5-2 hours
**Dependencies**: Phase 3

Create comprehensive documentation for `/lean` command and lean-implementer agent.

### Tasks

- [ ] Create command guide `.claude/docs/guides/commands/lean-command-guide.md`
  - Overview: What /lean does, when to use it
  - Syntax: Command arguments, flags, examples
  - Workflow integration: /plan → /lean → /test pattern
  - MCP tool usage: Which tools are invoked, rate limits
  - Proof summaries: Format, content, location
  - Troubleshooting: Common errors and solutions

- [ ] Update `.claude/agents/README.md`
  ```markdown
  ### lean-implementer
  - **Model**: sonnet-4.5
  - **Purpose**: AI-assisted Lean 4 theorem proving and formalization
  - **Used By**: /lean command
  - **Input**: Lean file path or plan with Lean theorem stubs
  - **Output**: Completed proofs with summaries
  - **Key Features**: MCP tool integration, Mathlib search, tactic exploration
  ```

- [ ] Update `.claude/docs/reference/standards/command-reference.md`
  - Add /lean command entry with syntax and description
  - Cross-reference to lean-command-guide.md

- [ ] Create implementation summary `.claude/specs/026_lean_command_orchestrator_implementation/summaries/001-implementation-summary.md`
  - Metadata: Date, spec, status
  - Implementation: Phase-by-phase summary
  - Artifacts: Command file, agent file, test plan
  - Next steps: Integration with ProofChecker, performance optimization

- [ ] Update project TODO.md
  - Mark spec 026 as COMPLETE
  - Add follow-up tasks (if any)

- [ ] Create example Lean plans
  - Example 1: Simple theorem proving (commutativity, associativity)
  - Example 2: Modal logic formalization (TM axioms)
  - Example 3: Complex proof (induction, multiple lemmas)

- [ ] Add troubleshooting section
  - MCP server not found → Install lean-lsp-mcp
  - lakefile not found → Not a Lean project
  - Rate limit exceeded → Reduce search tool usage
  - Proof verification failed → Check diagnostics

**Completion Criteria**:
- Command guide created with 6+ sections
- Agent README updated with lean-implementer entry
- Implementation summary complete
- 3+ example Lean plans created
- Troubleshooting section with 4+ common issues

---

## Phase 5: Integration Testing [NOT STARTED]

**Duration**: 1-2 hours
**Dependencies**: Phase 4

Test integration with existing .claude/ workflows and real ProofChecker project.

### Tasks

- [ ] Test /plan → /lean workflow
  - Run: `/plan "Formalize TM modal axioms in Lean"`
  - Verify: Plan created with Lean theorem stubs
  - Run: `/lean [plan-file]`
  - Verify: Theorems proven, plan checkboxes updated

- [ ] Test /lean → /test workflow
  - Run: `/lean [lean-file]`
  - Verify: Proofs completed
  - Run: `/test [lean-project]`
  - Verify: Tests execute, compilation succeeds

- [ ] Test with real ProofChecker formalization
  - Create plan for TM axioms (MT, M4, MB, T4, TA, TL, MF, TF)
  - Run: `/lean [plan-file]`
  - Verify: Axioms proven or partially proven
  - Document any failures for future improvement

- [ ] Test error recovery
  - Introduce syntax error in Lean file
  - Run: `/lean [lean-file]`
  - Verify: Diagnostics detected, error logged
  - Verify: Graceful failure with actionable message

- [ ] Test /todo integration
  - Run: `/lean [plan-file]`
  - Run: `/todo`
  - Verify: Completed proofs reflected in TODO.md

- [ ] Test checkpoint resumption (if applicable)
  - Run: `/lean [large-plan]` (simulated context exhaustion)
  - Verify: Checkpoint saved
  - Run: `/lean --resume [checkpoint]`
  - Verify: Resumption from checkpoint

**Completion Criteria**:
- All integration tests pass
- Real ProofChecker formalization attempted
- Error recovery tested and working
- TODO.md integration verified

---

## Acceptance Criteria

- [ ] `/lean` command proves simple theorems (add_comm, mul_comm) successfully
- [ ] MCP tools invoked correctly without errors
- [ ] Proof summaries created with tactic explanations and references
- [ ] Diagnostics checked and reported (no errors for valid proofs)
- [ ] All .claude/ standards followed (command authoring, error logging, output formatting)
- [ ] Documentation complete (command guide, agent README, examples)
- [ ] Integration with /plan and /test workflows verified
- [ ] Standards validation passes (no ERROR-level violations)

## Notes

### Lean-Specific Considerations

1. **MCP Tool Rate Limits**: External search tools (`lean_leansearch`, `lean_loogle`, `lean_leanfinder`, `lean_state_search`, `lean_hammer_premise`) share 3 requests/30s combined limit. Prioritize `lean_local_search` (no limit).

2. **Proof Granularity**: Lean theorem proving is tactic-level iteration (fine-grained), not phase-level iteration (coarse-grained). Each theorem is a separate proof goal.

3. **Lean Style Guide Compliance**: Proofs must follow LEAN_STYLE_GUIDE.md (snake_case functions, PascalCase types, 100-char line limit, 2-space indentation).

4. **Tactic Development Patterns**: Use METAPROGRAMMING_GUIDE.md and TACTIC_DEVELOPMENT.md for custom tactic implementation (if needed for ProofChecker automation).

5. **Testing Requirements**: Every public definition needs tests per LEAN_STYLE_GUIDE.md Section 7.

### Future Enhancements

1. **lean-coordinator Agent**: If Lean workflow diverges significantly from general implementation, consider creating lean-coordinator (similar to implementer-coordinator) for wave-based parallel theorem proving.

2. **Auto-Routing Integration**: Integrate lean-implementer into implementer-coordinator with auto-detection (`.lean` file → route to lean-implementer instead of implementation-executor). This would enable `/implement` to handle Lean plans automatically.

3. **Context-Aware Tactic Selection**: Use proof state analysis to select optimal tactics (currently pattern-based).

4. **Proof Refactoring**: Implement proof simplification after successful tactic application.

5. **Interactive Proof Mode**: Enable step-by-step tactic exploration with user feedback.

---

**Plan Created**: 2025-12-02
**Total Estimated Hours**: 8-12 hours
**Phases**: 6 (including Phase 0 for standards compliance)
**Key Deliverables**: /lean command, lean-implementer agent, comprehensive documentation, test suite

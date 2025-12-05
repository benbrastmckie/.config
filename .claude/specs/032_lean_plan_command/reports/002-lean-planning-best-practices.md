# Lean Theorem Proving Implementation Plan Best Practices

## Metadata
- **Date**: 2025-12-03
- **Agent**: research-specialist
- **Topic**: Lean theorem proving implementation plan best practices
- **Report Type**: best practices
- **Research Complexity**: 3

## Executive Summary

Lean 4 formalization projects benefit significantly from blueprint-driven planning methodologies that track dependencies and progress via dependency graphs. AI-assisted theorem proving tools like LeanDojo, COPRA, and DeepSeek-Prover-V2 require substantial context (up to 163K tokens) and benefit from proof decomposition strategies. Best practices emphasize file-level organization with namespace management, incremental proof development using tactics, and mathlib integration for reusable lemmas.

## Findings

### 1. Project Structure and Organization

#### File Organization Best Practices

**Lake Project Structure** (Source: Lean Theorem Prover ArchWiki):
- Lean 4 projects use Lake as the build system and package manager
- Standard directory structure:
  - `.lake/` - Build artifacts and dependencies
  - `{ProjectName}/` - Library source files (accessible via `import {ProjectName}.*`)
  - `lakefile.toml` or `lakefile.lean` - Package configuration with dependencies
  - `lake-manifest.json` - Locks dependency versions for reproducibility
  - `lean-toolchain` - Specifies exact Lean version

**File Naming Conventions** (Source: PhysLean Getting Started):
- Use descriptive names with only alphabetic characters
- Each word capitalized (PascalCase): `MyNewFile.lean`
- Only one `.lean` file allowed in project root directory
- Other files must be in subdirectories
- Update main import file (e.g., `PhysLean.lean`) with new files in alphabetical order

**Namespace Organization** (Source: Theorem Proving in Lean 4):
- Lean groups definitions and theorems into namespaces for organization
- Namespaces organize data; sections declare variables for insertion in definitions
- Namespaces enable modular code structure and prevent naming conflicts

#### Dependency Management

**Mathlib Integration** (Source: mathlib4 contribution guidelines):
- Add mathlib as dependency: `require "leanprover-community" / "mathlib"` in lakefile
- For theorem proving packages: `lake new <package-name> math` generates mathlib-ready configuration
- Dependencies installed in `.lake` folder
- `lake exe cache get` downloads precompiled mathlib binaries (faster than building from source)

**Dependency Visualization** (Source: lean-graph):
- Tool available for automatic extraction and visualization of theorem dependencies as graphs
- Helps understand proof structure and identify circular dependencies

### 2. Blueprint Methodology for Planning

#### What is Blueprint-Driven Formalization?

**Core Concept** (Source: Formalizing PFR in Lean4 using Blueprint - Terry Tao):
- Blueprint = LaTeX document with "ordinary math" listing definitions, theorems, and proof outlines
- Links mathematical statements to Lean 4 code implementations
- Automatically generates HTML/PDF versions plus dependency graph showing progress
- Enables asynchronous work: later stages can begin before earlier stages are fully formalized

**Key Features** (Source: leanblueprint README):
- Originally created in 2020 for Sphere Eversion Project
- PlasTeX plugin for Lean 4 projects
- Tracks both statements and proofs separately
- Color-coded dependency graph shows formalization progress

#### Blueprint Macros and Metadata

**Essential LaTeX Macros** (Source: leanblueprint):
- `\lean{namespace.theorem_name}` - Links TeX to Lean declaration names
- `\leanok` - Marks environment as fully formalized
- `\notready` - Marks environment not ready for formalization (needs blueprint work)
- `\mathlibok` - Marks nodes already merged into mathlib

**Dependency Graph Visualization** (Source: Terry Tao blog):
- White bubble with green border: Statement formalized, proof not ready (missing prerequisites)
- Blue bubble with green border: Statement formalized, proof ready to implement
- Provides rough snapshot of formalization progress
- Automatically generated from blueprint structure

#### Blueprint Granularity

**Planning Level** (Source: Terry Tao blog):
- Blueprint works at theorem/lemma level granularity
- Each theorem is a node in dependency graph
- Proof outlines included but not full tactic sequences
- Allows flexibility in implementation approach while maintaining structure

**Refactoring Considerations** (Source: Terry Tao blog):
- Well-written blueprints minimize major refactoring needs
- Minor refactoring straightforward (e.g., adding non-zero hypotheses)
- Blueprint structure should be written with reasonable care initially
- Good intuition during blueprint phase prevents later restructuring

#### Notable Blueprint Projects

**Production Usage** (Source: LeanProject template):
- Prime Number Theorem and More (Alex Kontorovich et al.)
- Infinity Cosmos (Emily Riehl et al.)
- Analytic Number Theory Exponent Database (Terence Tao et al.)
- Liquid Tensor Experiment (Scholze)
- Template available at pitmonticone/LeanProject repository

### 3. Proof Strategy Patterns

#### Tactic-Based Development

**Proof Style Trade-offs** (Source: Theorem Proving in Lean 4):
- Tactic-style vs term-style proofs serve different purposes
- Tactics support incremental proof writing, decomposing goals step-by-step
- Tactic proofs can be harder to read (requires predicting instruction results)
- But: shorter, easier to write, gateway to automation
- Lean allows mixing both styles freely

**Proof Decomposition** (Source: Theorem Proving in Lean 4):
- Tactics naturally support decomposition: work on goals one step at a time
- Informal mathematical proof structure: "unfold definition, apply lemma, simplify"
- Formal tactics mirror this: corresponding tactic instructions for each step
- Proof state = ordered sequence of goals (contexts + types to inhabit)

#### Common Tactics Reference

**Core Tactics** (Source: Lean 4 Tactic Reference):

1. **intro** - Introduces hypotheses into context
   - `intro h` fills goal `p ∨ q → q ∨ p` with `fun h => ?m`
   - Supports pattern-matching syntax
   - `revert` is the inverse operation

2. **apply** - Applies theorem/definition to goal
   - `apply Or.inr` fills hole with application `Or.inr ?m3`
   - `apply?` searches environment for applicable theorems
   - Resolves conditions when possible with `solve_by_elim`

3. **exact** - Provides exact proof term
   - `exact h1` fills hole directly with term
   - `exact?` searches for lemma that completely solves goal
   - `refine e` like exact but converts unsolved holes to new goals

4. **rw** (rewrite) - Rewrites using equality
   - `rw [h]` or `rw [← h]` for forward/backward rewriting
   - `rw?` searches library for applicable rewrites
   - Can exclude lemmas: `rw? [-my_lemma]`

5. **simp** (simplifier) - Conditional term rewriting
   - Repeatedly replaces subterms using `A = B` or `A ↔ B` facts
   - Rewrites until no more applicable rules
   - `simpa` exists for non-terminal simp (mathlib policy)
   - `norm_cast` is specialized simp for moving casts upward

6. **split** - Case splits for if-then-else and match
   - Breaks nested expressions into separate cases
   - Generates at most n subgoals for n-case match

7. **rcases** - Recursive case splitting
   - Pattern-driven hypothesis decomposition
   - Angle brackets for extraction: `⟨h1, h2⟩`
   - Vertical bars for case separation: `h1 | h2`

**Tactic Structuring** (Source: Theorem Proving in Lean 4):
- Long tactic sequences can obscure proof structure
- Use indentation and comments to show structure
- Mix term-style and tactic-style for clarity
- Tactics like `with_reducible` control definition unfolding

#### Proof Debugging Techniques

**Common Error: Type Mismatch** (Source: Lean 4 GitHub Issues):
- Dependent types can cause "identical types" to mismatch
- Example: `a.2` and `b.2` have types `β a.fst` vs `β b.fst` (different!)
- Natural number arithmetic: `0` ≠ `0 + m` definitionally
- Reducibility issues: unfolding too many/few definitions

**Debugging Options** (Source: Lean 4.12.0 Release):
- `set_option pp.all true` - Shows all type information
- `set_option pp.all false` - Reverts to normal pretty printing
- `pp.exprSizes` - Shows expression sizes with sharing info
- Trace options for simp: `trace.Debug.Meta.Tactic.simp`

**Debugging Tactics** (Source: Lean Reference Manual):
- Display current state in tracing buffer
- Type check expressions and trace their types
- Tactics can fail (no progress, inappropriate goal)
- Kernel verifies all tactic-produced results for correctness

### 4. AI Integration Patterns

#### LeanDojo Infrastructure

**Core Capabilities** (Source: LeanDojo):
- Python library bridging ML world and Lean prover
- Gym-like environment: observe state, run tactics, receive feedback
- LeanDojo Benchmark: 98,734 theorems (Lean 3), 122,517 theorems (Lean 4)
- Includes tactics and premises from mathlib/mathlib4

**Related Tools** (Source: LeanDojo ecosystem):
- **Lean Copilot**: LLMs natively in Lean for proof automation
  - Suggests tactics/premises, searches for proofs
  - `search_proof` combines LLM-generated tactics with aesop
- **ReProver**: Retrieval-based approach using Dense Passage Retriever
- **LeanAgent**: Lifelong learning framework (no catastrophic forgetting)

#### COPRA: In-Context Learning Agent

**Architecture** (Source: COPRA arXiv):
- In-COntext PRoof Agent using GPT-4 (no fine-tuning)
- Stateful backtracking search with tactic proposals
- Execution feedback builds next prompt iteratively
- Retrieved lemmas from external database supplement context

**Workflow** (Source: COPRA):
1. Input: Formal theorem statement + optional NL hints
2. Each step: LLM proposes next tactic
3. Tactic executed in proof environment
4. Feedback + search history + retrieved lemmas → next prompt

**Performance** (Source: COPRA):
- Outperforms few-shot GPT-4 on miniF2F (Lean) and CompCert (Coq)
- Better than REPROVER (fine-tuned) on pass@1 metric
- Requires OpenAI API key in `.secrets/openai_key.json`
- Experiments configured in `./src/main/config/experiments.yaml`

#### DeepSeek-Prover-V2

**Context Requirements** (Source: DeepSeek-Prover-V2):
- Context window: 163,840 tokens (up to 128K-163K usable)
- Handles large problems, multi-theorem proofs, multiple lemmas simultaneously
- Can reason over extensive mathematical content in single input

**Input Format** (Source: DeepSeek-Prover-V2):
```lean
import Mathlib
import Aesop
set_option maxHeartbeats 0

open BigOperators Real Nat Topology Rat

theorem statement_name : theorem_statement := by
  sorry

-- Prompt: Complete the Lean 4 code above. Provide a detailed proof plan
-- outlining main steps and strategies. Highlight key ideas, intermediate
-- lemmas, and proof structures.
```

**Architecture** (Source: DeepSeek-Prover-V2):
- Mixture-of-Experts: 671B total parameters, 37B active per inference
- Recursive data synthesis pipeline using general-purpose model
- Analyzes NL problems, breaks into formal subgoals, produces CoT reasoning
- Requires Lean 4 ≥ 4.5 and customized mathlib4 submodule

**Performance** (Source: DeepSeek-Prover-V2):
- 88.9% pass ratio on MiniF2F-test (state-of-the-art)
- Solves 49/658 PutnamBench problems
- First to reach "medal-worthy" performance on formal math competitions

#### TheoremLlama Framework

**Training Methodology** (Source: TheoremLlama):
- NL-FL dataset generation and bootstrapping for alignment
- Curriculum learning and block training techniques
- Iterative proof writing method
- 36.48% accuracy on MiniF2F-Valid, 33.61% on MiniF2F-Test
- Surpasses GPT-4 baseline (22.95% / 25.41%)

#### APOLLO Pipeline

**Proof Repair Strategy** (Source: APOLLO):
- Model-agnostic pipeline combining Lean compiler with LLM reasoning
- When proof has remaining `sorry`'s: treat each as new lemma
- Extract local context, recursively prove sub-lemmas
- Makes progress by breaking down incomplete steps
- Low sampling budget, high success rate

#### Parallelization Strategies

**DeepSeek-Prover Approach** (Source: DeepSeek-Prover):
- Large search space for proofs causes delays
- Unprovable statements processed until timeout (wasteful)
- Mitigation: Prove negated statements in parallel
- Accelerates proof generation process

**LeanNavigator Efficiency** (Source: LeanNavigator):
- Embedding-based retrieval for tactic generation
- More efficient than generative models for tactic selection
- Generated 4.7M theorems in Lean (1B tokens total)
- Previous dataset only 57M tokens

### 5. Proof Strategy Metadata

#### Plan Structure for Lean Projects

**Granularity Levels**:
1. **File-level**: Organize by mathematical topic (topology, algebra, analysis)
2. **Theorem-level**: Individual theorems as planning units (blueprint approach)
3. **Proof-level**: Tactic sequences (too fine-grained for planning)

**Recommended Planning Granularity**: Theorem-level
- Each theorem/lemma is one planning unit
- Dependencies tracked between theorems
- Tactics chosen during implementation, not planning
- Allows flexibility while maintaining structure

#### Metadata for Lean Plans

**Essential Fields**:
1. **Theorem Name**: Full namespace path (e.g., `MyProject.Topology.theorem_name`)
2. **Statement**: Formal Lean 4 statement with types
3. **Dependencies**: List of required theorems/lemmas (namespace paths)
4. **Mathlib Dependencies**: External lemmas from mathlib needed
5. **Proof Strategy**: High-level approach (induction, contradiction, direct proof, etc.)
6. **Status**: Not Started / Statement Only / Proof Complete / Mathlib Ready
7. **Estimated Difficulty**: 1-5 scale based on proof complexity
8. **File Location**: Target file path in project structure

**Optional Fields**:
- Natural language description
- Proof outline (informal steps)
- Known obstacles or challenges
- Alternative proof approaches
- Related theorems for context

#### Dependency Tracking

**Blueprint-Style Dependencies** (Source: leanblueprint):
- Automatic extraction from `\lean{}` macro references
- Dependency graph generation (color-coded by status)
- Visual representation of proof structure
- Identifies bottlenecks (theorems blocking many others)

**Dependency Types**:
1. **Hard Dependencies**: Theorem A requires Theorem B's statement and proof
2. **Soft Dependencies**: Theorem A benefits from Theorem B but not required
3. **Mathlib Dependencies**: External dependencies (assumed proven)

**Parallel Execution Opportunities**:
- Theorems with no shared dependencies can be proven in parallel
- Blueprint graph identifies independent proof branches
- AI batch processing: submit independent theorems simultaneously

### 6. Success Metrics and Iteration

#### Proof Success Metrics

**Completion Metrics**:
- **Pass@1**: Proof succeeds on first attempt (COPRA, TheoremLlama benchmarks)
- **Pass@N**: Proof succeeds within N attempts
- **Proof Rate**: Percentage of theorems proven from benchmark set
- **Time to Proof**: Duration from start to successful proof

**Quality Metrics**:
- **Proof Length**: Number of tactic applications (shorter often better)
- **Mathlib Usage**: Reuse of existing lemmas (higher reuse = better)
- **Type Safety**: No `sorry` placeholders in final proof
- **Maintainability**: Proof survives mathlib updates (robust to changes)

#### Iteration and Error Handling

**Common Proof Errors** (Source: Lean 4 releases):
- **Type Mismatch**: Most common error, often from dependent types
- **Tactic Failed**: Tactic not applicable to current goal
- **Timeout**: Proof search exceeded resource limits
- **Unsolved Goals**: Proof incomplete, remaining obligations

**Iteration Strategies**:
1. **Tactic Refinement**: If tactic fails, try more specific variant
2. **Lemma Extraction**: If proof too complex, extract intermediate lemma
3. **Context Enrichment**: Add more hypotheses or import additional theorems
4. **Proof Strategy Change**: Switch from induction to direct proof, etc.

**AI Iteration Patterns** (Source: APOLLO):
- Recursive sub-lemma proving when stuck
- Extract local context for focused proof attempts
- Break down incomplete steps into smaller units
- Low sampling budget favors targeted iterations over exhaustive search

### 7. Integration with Existing Tools

#### Lean 4 LSP Integration

**Language Server Protocol Support**:
- Real-time type checking and error feedback
- Tactic state inspection at cursor position
- Auto-completion for theorems and tactics
- Go-to-definition for dependencies

**Planning Implications**:
- LSP can validate theorem statements before full proof
- Dependency graph can be extracted from LSP data
- Real-time feedback during implementation phase
- IDE integration enables rapid iteration

#### Mathlib Search and Documentation

**Search Tools**:
- `exact?` and `apply?` tactics search for applicable lemmas
- `rw?` suggests rewrites from library
- Mathlib documentation website with search functionality
- Zulip chat for community assistance

**Planning Recommendations**:
- Survey mathlib before planning: avoid reinventing proven theorems
- Identify reusable lemmas during research phase
- Plan imports explicitly (namespace management)
- Consider mathlib contribution path for general results

## Recommendations

### 1. Adopt Theorem-Level Plan Granularity

**Recommendation**: Use theorem/lemma as the atomic planning unit for /lean:plan command.

**Rationale**:
- Blueprint methodology (proven in production projects like PFR formalization, Liquid Tensor Experiment) operates at theorem level
- File-level planning too coarse (loses dependency information)
- Proof-level (tactic sequences) too fine-grained (limits flexibility)
- Theorem-level strikes optimal balance: trackable dependencies, flexible implementation

**Implementation**:
- Each plan phase represents one theorem or small group of related theorems
- Phase metadata includes: theorem name, formal statement, dependencies, proof strategy
- Dependency tracking enables wave-based parallel execution
- Natural mapping to blueprint LaTeX format for visualization

**Benefits**:
- Compatible with existing blueprint tooling
- Enables parallel proof attempts for independent theorems
- Provides clear progress tracking (% of theorems proven)
- Supports AI batch processing of independent proof goals

### 2. Include Rich Context for AI Prover Integration

**Recommendation**: Plan format should provide comprehensive context suitable for AI theorem provers (LeanDojo, COPRA, DeepSeek-Prover-V2).

**Rationale**:
- DeepSeek-Prover-V2 requires up to 163K tokens of context for complex proofs
- COPRA benefits from natural language hints about proof strategy
- AI provers need to see: theorem statement, dependencies, mathlib imports, proof approach
- Higher context quality correlates with higher proof success rates

**Implementation for /lean:plan**:
- **Theorem Statement**: Full formal Lean 4 code with types
- **Natural Language Description**: 2-3 sentence explanation of theorem meaning
- **Proof Strategy Hint**: High-level approach (e.g., "Use strong induction on n, applying triangle inequality at each step")
- **Required Imports**: Explicit mathlib namespaces needed
- **Dependency List**: Theorem names with namespace paths
- **Difficulty Estimate**: 1-5 scale to guide resource allocation
- **Example Context**: Similar proven theorems for reference

**Benefits**:
- Enables automated proof attempts via AI integration
- Provides human implementers with clear guidance
- Facilitates batching of similar-difficulty proofs
- Supports iterative refinement (if proof fails, revise hint)

### 3. Integrate Blueprint-Style Dependency Tracking

**Recommendation**: Implement dependency graph generation compatible with leanblueprint visualization format.

**Rationale**:
- Visual dependency graphs essential for large formalization projects
- Identifies bottleneck theorems blocking downstream proofs
- Enables parallel work streams on independent branches
- Provides stakeholders with clear progress visualization
- Terry Tao and other major projects rely on this methodology

**Implementation**:
- Parse plan file to extract theorem dependencies
- Generate DOT/GraphViz format dependency graph
- Color-code nodes by status: Not Started (white), Statement Only (white+green), Proof Complete (blue+green)
- Identify critical path (longest dependency chain)
- Flag circular dependencies as errors during plan validation

**Metadata Fields**:
```yaml
theorem_name: "MyProject.Topology.ContinuityLemma"
dependencies:
  - "MyProject.Topology.OpenSetDef"  # Hard dependency (required)
  - "Mathlib.Topology.Basic"         # Mathlib dependency
status: "statement_only"              # For graph coloring
```

**Benefits**:
- Immediate visual feedback on project structure
- Parallelization opportunities clearly visible
- Integration with existing blueprint tooling
- Standard format enables community collaboration

### 4. Support Progressive Proof Elaboration

**Recommendation**: Plan format should accommodate multi-stage proof development (statement → outline → complete proof).

**Rationale**:
- Blueprint methodology separates statement formalization from proof formalization
- Allows downstream theorems to proceed with `sorry` placeholders
- Matches APOLLO's recursive sub-lemma proving strategy
- Enables "breadth-first" formalization: all statements first, then proofs

**Implementation**:
- **Status Field**: `not_started`, `statement_only`, `proof_sketch`, `proof_complete`, `mathlib_ready`
- **Proof Outline**: Optional field with informal proof steps (fills before tactics)
- **Placeholders**: Track which theorems use `sorry` and where
- **Refinement Path**: Link to revised plan if proof approach changes

**Example Phase Structure**:
```markdown
### Phase 1: Formalize Theorem Statements
- Status: proof_sketch
- Statement: [Full Lean 4 code]
- Outline: "1. Assume P(n) for all k < n. 2. Show P(n) by cases..."
- Implementation: Use `sorry` for proof body initially

### Phase 2: Complete Proofs
- Status: proof_complete
- Dependencies: Phase 1 (statements needed)
- Implementation: Replace `sorry` with full tactic sequences
```

**Benefits**:
- Unblocks parallel work (downstream theorems can use statements)
- Matches proven formalization workflows
- Enables early validation of theorem statements
- Supports incremental progress tracking

### 5. Design for AI Batch Processing and Parallelization

**Recommendation**: Structure plans to enable efficient batch processing of proofs via AI provers.

**Rationale**:
- DeepSeek-Prover parallelizes negated statement proving
- LeanNavigator uses embedding-based retrieval for efficiency
- Independent theorems can be sent to AI in parallel
- Batch processing reduces wall-clock time by 40-60% (per existing /implement parallelization)

**Implementation**:
- **Dependency Waves**: Group theorems by dependency level (wave 0 = no deps, wave 1 = depends only on wave 0, etc.)
- **Batch Size**: Configure max parallel AI prover invocations (e.g., 5 simultaneous proofs)
- **Timeout Handling**: Set per-theorem timeout (prevents unprovable statements from blocking batch)
- **Retry Logic**: Failed proofs returned to queue with refined hints
- **Resource Limits**: Respect API rate limits and token quotas

**Plan Metadata for Batching**:
```yaml
parallelization:
  wave: 0                    # Dependency wave (0 = no dependencies)
  estimated_tokens: 8500     # Context size estimate
  timeout_seconds: 300       # Max proving time
  retry_count: 0             # Increments on failure
```

**Benefits**:
- Dramatic reduction in total proving time
- Efficient use of AI prover resources
- Automatic handling of provable/unprovable classification
- Scales to large formalization projects

### 6. Include Mathlib Survey in Planning Phase

**Recommendation**: /lean:plan should explicitly include a mathlib search step to identify reusable lemmas.

**Rationale**:
- Mathlib has 210,000+ proven theorems (as of May 2025)
- Reinventing proven theorems wastes effort
- Higher mathlib usage correlates with proof maintainability
- `exact?`, `apply?`, `rw?` tactics rely on knowing what's available

**Implementation**:
- **Pre-Planning Research**: Search mathlib for related theorems before creating plan
- **Dependency Documentation**: Explicitly list mathlib lemmas each theorem will use
- **Import Planning**: Generate required import statements for each file
- **Gap Analysis**: Identify which theorems are novel (not in mathlib)

**Example Mathlib Survey Output**:
```markdown
### Mathlib Analysis for ContinuityLemma

**Existing Lemmas**:
- `Mathlib.Topology.Continuous.comp` - Composition of continuous functions
- `Mathlib.Topology.OpenSet.union` - Unions of open sets are open

**Novel Contribution**:
- Our theorem extends to non-Hausdorff spaces (not in mathlib)

**Required Imports**:
```lean
import Mathlib.Topology.Basic
import Mathlib.Topology.Continuous
```
```

**Benefits**:
- Avoids duplicate work
- Improves proof success rate (reuse proven lemmas)
- Identifies contribution opportunities (novel theorems for mathlib PR)
- Generates correct import statements automatically

### 7. Integrate Error Classification and Iteration Metadata

**Recommendation**: Track common error patterns and iteration history in plan metadata.

**Rationale**:
- Type mismatch is most common Lean error (needs specific handling)
- AI provers benefit from error feedback in retry attempts
- Iteration history informs difficulty estimates
- Error patterns guide proof strategy selection

**Implementation**:
- **Error Types**: Track occurrences of type_mismatch, tactic_failed, timeout, unsolved_goals
- **Iteration Log**: Record each proof attempt with outcome
- **Strategy Evolution**: Document proof approach changes
- **Success Signals**: Identify which tactics/strategies worked

**Metadata Schema**:
```yaml
theorem_name: "MyProject.Algebra.CommutativeLemma"
iteration_history:
  - attempt: 1
    strategy: "direct_proof"
    error: "type_mismatch"
    details: "Dependent type issue with sigma types"
    duration_seconds: 45
  - attempt: 2
    strategy: "direct_proof_with_simp"
    error: "tactic_failed"
    details: "simp could not reduce goal"
    duration_seconds: 60
  - attempt: 3
    strategy: "cases_on_hypothesis"
    result: "success"
    duration_seconds: 120
    proof_length_tactics: 15
```

**Benefits**:
- Informs future proof attempts (avoid failed strategies)
- Enables learning across theorems (pattern recognition)
- Provides audit trail for difficult proofs
- Supports automated difficulty re-estimation

### 8. Design Plan Format for LSP Integration

**Recommendation**: Structure plans to leverage Lean 4 Language Server Protocol for real-time validation.

**Rationale**:
- LSP provides instant feedback on theorem statements
- Type checking happens before full proof attempts
- Dependency information available via LSP queries
- IDE integration improves human implementation experience

**Implementation**:
- **Statement Validation**: Check theorem statements are well-typed before adding to plan
- **Dependency Extraction**: Query LSP for actual theorem dependencies (compare to planned)
- **Tactic Suggestions**: LSP can suggest applicable tactics at each proof state
- **Real-Time Progress**: Update plan status as LSP confirms proof completion

**Integration Pattern**:
1. Plan generated with theorem statements
2. LSP validates each statement (type checking)
3. Implementation phase: LSP provides tactic suggestions
4. LSP confirms proof completion (no `sorry` remaining)
5. Plan automatically updated with completion status

**Benefits**:
- Catch statement errors during planning (before implementation)
- Accurate dependency tracking (actual vs. planned)
- Improved implementation efficiency (LSP-assisted tactics)
- Automatic progress tracking (LSP confirms completion)

### 9. Support Multiple Proof Strategy Approaches

**Recommendation**: Plan metadata should accommodate alternative proof strategies for robust iteration.

**Rationale**:
- If primary strategy fails, alternative approaches avoid full replanning
- Different strategies suit different AI provers (GPT-4 vs DeepSeek vs symbolic)
- Human implementers benefit from strategy options
- Matches APOLLO's approach (try multiple tactics per `sorry`)

**Implementation**:
```yaml
theorem_name: "MyProject.NumberTheory.PrimeDivisibility"
proof_strategies:
  - name: "strong_induction"
    priority: 1
    description: "Induction on n with strong induction hypothesis"
    estimated_difficulty: 3
    suitable_for: ["human", "copra", "deepseek"]
  - name: "contradiction"
    priority: 2
    description: "Assume negation and derive contradiction via Euclid's lemma"
    estimated_difficulty: 4
    suitable_for: ["human", "copra"]
  - name: "direct_construction"
    priority: 3
    description: "Directly construct prime factor using well-ordering"
    estimated_difficulty: 2
    suitable_for: ["all"]
```

**Benefits**:
- Robustness to primary strategy failure
- Optimizes prover selection (match strategy to prover strengths)
- Reduces replanning overhead
- Provides human implementers with options

### 10. Include Success Criteria and Test Cases

**Recommendation**: Each theorem should have explicit success criteria beyond "proof compiles".

**Rationale**:
- Proof compilation is necessary but not sufficient
- Want proofs that are maintainable, readable, efficient
- Test cases validate theorem correctness (not just well-typedness)
- Mathlib contribution requires quality standards

**Implementation**:
```yaml
theorem_name: "MyProject.Analysis.ConvergenceLemma"
success_criteria:
  - criterion: "proof_compiles"
    required: true
    validation: "Lean compiler accepts proof (no errors)"
  - criterion: "no_sorry"
    required: true
    validation: "No `sorry` placeholders remain"
  - criterion: "proof_length"
    required: false
    target: "< 50 tactic applications"
    rationale: "Shorter proofs more maintainable"
  - criterion: "mathlib_style"
    required: false
    validation: "Follows mathlib style guide (simp usage, naming)"
  - criterion: "test_cases"
    required: true
    validation: "Concrete examples verify theorem correctness"

test_cases:
  - description: "Convergence of geometric series (r = 0.5)"
    input: "geometric_series 0.5"
    expected: "converges_to 2"
  - description: "Non-convergence for r = 1.5"
    input: "geometric_series 1.5"
    expected: "diverges"
```

**Benefits**:
- Quality assurance beyond type checking
- Concrete examples aid understanding
- Mathlib-ready proofs (if contributing back)
- Prevent "technically correct but unmaintainable" proofs

## References

### Web Sources

#### Lean 4 Official Documentation
- [Theorem Proving in Lean 4](https://leanprover.github.io/theorem_proving_in_lean4/) - Official guide to using Lean as theorem prover
- [Mathematics in Lean Release v4.19.0](https://leanprover-community.github.io/mathematics_in_lean/mathematics_in_lean.pdf) - Comprehensive mathematics formalization guide
- [Lean 4 Tactic Reference](https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Tactic-Reference/) - Complete tactic documentation
- [Lean 4 GitHub Repository](https://github.com/leanprover/lean4) - Source code and issue tracker
- [Lake Build System README](https://github.com/leanprover/lean4/blob/master/src/lake/README.md) - Project structure and dependency management

#### Mathlib Resources
- [How to contribute to mathlib](https://leanprover-community.github.io/contribute/index.html) - Contribution guidelines and workflow
- [mathlib4 GitHub Repository](https://github.com/leanprover-community/mathlib4) - Mathematical library source
- [Mathematics in Lean Introduction](https://leanprover-community.github.io/mathematics_in_lean/C01_Introduction.html) - Getting started with mathlib

#### Blueprint Methodology
- [Formalizing the proof of PFR in Lean4 using Blueprint](https://terrytao.wordpress.com/2023/11/18/formalizing-the-proof-of-pfr-in-lean4-using-blueprint-a-short-tour/) - Terry Tao's detailed blueprint workflow
- [leanblueprint GitHub Repository](https://github.com/PatrickMassot/leanblueprint) - PlasTeX plugin for blueprint generation
- [LeanProject Template](https://github.com/pitmonticone/LeanProject) - Blueprint-driven project template
- [Lean blueprint dependency graph discussion](https://leanprover-community.github.io/archive/stream/113488-general/topic/lean.20blueprint.20dependency.20graph.html) - Zulip chat on dependency tracking

#### AI Theorem Proving
- [LeanDojo: AI-Driven Formal Theorem Proving](https://leandojo.org/) - Main project page
- [Lean Copilot Documentation](https://leandojo.org/leancopilot.html) - LLM integration for proof automation
- [LeanDojo GitHub](https://github.com/lean-dojo/LeanCopilot) - Copilot source code
- [COPRA: An In-Context Learning Agent for Formal Theorem-Proving](https://arxiv.org/abs/2310.04353) - Research paper on GPT-4 based proving
- [COPRA GitHub Repository](https://github.com/trishullab/copra) - Implementation and experiments
- [DeepSeek-Prover-V2 GitHub](https://github.com/deepseek-ai/DeepSeek-Prover-V2) - State-of-the-art open source prover
- [DeepSeek-Prover-V2: Open-Source AI for Lean 4](https://medium.com/aimonks/deepseek-prover-v2-open-source-ai-for-lean-4-formal-theorem-proving-ab7f9910576b) - Overview article
- [TheoremLlama: Transforming General-Purpose LLMs into Lean4 Experts](https://arxiv.org/abs/2407.03203) - LLM fine-tuning for theorem proving
- [APOLLO: Automated Proof Repair](https://arxiv.org/html/2505.05758v1) - LLM and Lean collaboration for proof generation
- [Process-Driven Autoformalization in Lean 4](https://arxiv.org/html/2406.01940v1) - FormL4 benchmark for LLM evaluation

#### Project Organization
- [Lean Theorem Prover - ArchWiki](https://wiki.archlinux.org/title/Lean_Theorem_Prover) - Installation and project structure
- [PhysLean: Getting Started](https://physlean.com/GettingStarted) - File organization best practices
- [Lean Project Setup Guide](https://leanprover-community.github.io/install/project.html) - Creating new Lean projects
- [lean-graph: Theorem Dependency Visualization](https://github.com/patrik-cihal/lean-graph) - Automatic dependency graph extraction
- [Zulip: Required Project Structure](https://leanprover-community.github.io/archive/stream/270676-lean4/topic/Required.20Project.20Structure.3F.html) - Community discussion on standards

#### Formalization Methodologies
- [Process-Driven Autoformalization in Lean 4 (OpenReview)](https://openreview.net/forum?id=k8KsI84Ds7) - Formalization workflow research
- [Exploring Formalisation: A Primer in Human-Readable Mathematics in Lean 3](https://loeh.app.uni-regensburg.de/mapa/main.pdf) - Formalization pedagogy
- [Logic Formalization in Lean 4](https://formalizedformallogic.github.io/Book/) - Formal logic textbook in Lean

#### Debugging and Error Handling
- [Lean 4 Releases](https://github.com/leanprover/lean4/releases/tag/v4.12.0) - Version history and debugging features
- [Lean 4.16.0 Release Notes](https://lean-lang.org/doc/reference/latest/releases/v4.16.0/) - Recent improvements
- [Type Mismatch Error Reports](https://github.com/leanprover/lean4/issues/333) - Common error patterns
- [Interacting with Lean](https://lean-lang.org/theorem_proving_in_lean4/interacting_with_lean.html) - IDE integration and debugging

### Local Files

No local files were analyzed for this research (web-only research phase).

### Related Specifications

- See `/home/benjamin/.config/.claude/specs/032_lean_plan_command/reports/001-lean-infrastructure-research.md` for Lean infrastructure and lean-lsp-mcp integration details
- Future work: `/lean:plan` command implementation plan (to be created by plan-architect)

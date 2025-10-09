# Formal Verification

## Purpose

This document describes formal verification tool integration in the NeoVim configuration, including support for Lean 4 theorem prover and model-checking workflows in the philosophy domain.

## Lean 4 Integration

### Overview

Lean 4 is an interactive theorem prover and functional programming language used for mathematical formalization and verified programming.

**Key Features**:
- Interactive proof development
- Real-time type checking
- Tactic-based proof construction
- Infoview for goal visualization
- Mathematics library (Mathlib)

**Use Cases**:
- Mathematical theorem proving
- Program verification
- Formal logic development
- Type theory research

### Lean Plugin Configuration

**Plugin**: lean.nvim
**File**: `lua/neotex/plugins/text/lean.lua`

**Features Provided**:
- Syntax highlighting for Lean 4 code
- LSP integration with lean4 language server
- Infoview display for proof state
- Abbreviation expansion (Unicode math symbols)
- Real-time error and warning display

### Lean Workflow

```
┌─────────────────────────────────────┐
│ Edit Lean File (.lean)              │
│ • Write definitions                 │
│ • State theorems                    │
│ • Develop proofs with tactics       │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Lean LSP Server                     │
│ • Type checks code                  │
│ • Reports errors                    │
│ • Provides goal state               │
│ • Offers completions                │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Infoview Display                    │
│ • Shows current proof goals         │
│ • Displays context (hypotheses)     │
│ • Updates as cursor moves           │
│ • Shows tactic results              │
└─────────────────────────────────────┘
```

### Infoview Usage

The Infoview displays the current proof state at cursor position.

**Opening Infoview**:
- Automatically opens when editing `.lean` files
- Manual toggle available (check plugin configuration)

**Information Displayed**:
- **Goals**: What remains to be proved
- **Context**: Available hypotheses and definitions
- **Types**: Type information for terms
- **Tactic Results**: Effect of each tactic application

**Example**:
```lean
theorem add_comm (a b : Nat) : a + b = b + a := by
  -- Infoview shows goal: ⊢ a + b = b + a
  induction a with
  | zero =>
    -- Infoview shows goal: ⊢ 0 + b = b + 0
    simp
  | succ n ih =>
    -- Infoview shows goal: ⊢ succ n + b = b + succ n
    -- with hypothesis: ih : n + b = b + n
    simp [ih]
```

### Unicode Input

Lean uses Unicode symbols for mathematical notation.

**Abbreviation Expansion**:
Type backslash sequences that expand to Unicode:
- `\alpha` → α
- `\to` → →
- `\forall` → ∀
- `\exists` → ∃
- `\lambda` → λ
- `\nat` → ℕ
- `\int` → ℤ

**Completion**:
- LSP provides completion for Unicode alternatives
- Type character, see Unicode options
- Select desired symbol

### Lean Project Structure

Typical Lean project organization:
```
MyProject/
├── lakefile.lean          # Lake build configuration
├── lean-toolchain         # Lean version specification
├── MyProject/             # Source directory
│   ├── Basic.lean         # Basic definitions
│   ├── Theorems.lean      # Main theorems
│   └── Tactics.lean       # Custom tactics
└── MyProject.lean         # Main entry point
```

**Lake**: Lean's build system and package manager
- Manages dependencies (e.g., Mathlib)
- Builds projects
- Runs tests

### Common Lean Tactics

| Tactic | Purpose | Example |
|--------|---------|---------|
| `rfl` | Reflexivity | Proves `a = a` |
| `simp` | Simplification | Applies simplification lemmas |
| `rw` | Rewrite | Replaces using equality |
| `intro` | Introduction | Introduces assumption/variable |
| `apply` | Apply theorem | Uses existing theorem |
| `induction` | Induction | Proof by induction |
| `cases` | Case split | Pattern match on constructor |
| `exact` | Exact proof | Provides exact term |

**Tactic Workflow**:
1. State theorem
2. Enter tactic mode with `by`
3. Apply tactics to transform goal
4. Check Infoview after each tactic
5. Complete when no goals remain

### Example: Mathematical Proof

```lean
import Mathlib.Data.Nat.Basic

theorem nat_add_zero (n : Nat) : n + 0 = n := by
  -- Goal: ⊢ n + 0 = n
  rfl  -- Proven by reflexivity

theorem nat_zero_add (n : Nat) : 0 + n = n := by
  -- Goal: ⊢ 0 + n = n
  simp  -- Simplified using Nat.zero_add

theorem add_comm_proof : ∀ (a b : Nat), a + b = b + a := by
  intro a b
  -- Goal: ⊢ a + b = b + a
  induction b with
  | zero =>
    -- Goal: ⊢ a + 0 = 0 + a
    rw [nat_add_zero, nat_zero_add]
  | succ n ih =>
    -- Goal: ⊢ a + succ n = succ n + a
    -- Hypothesis: ih : a + n = n + a
    rw [Nat.add_succ, ih, Nat.succ_add]
```

## Model-Checker Integration

### Overview

Model-checking tools verify properties of formal models, particularly useful in philosophy for analyzing argument structures and modal logic.

**Typical Applications**:
- Modal logic verification
- Argument validity checking
- Possible worlds semantics
- Consistency checking

**Common Tools**:
- **MLSolver**: Modal logic solver
- **PRISM**: Probabilistic model checker
- **NuSMV**: Symbolic model checker
- **Spin**: Protocol verification

### Integration Approach

Model-checkers typically run as external tools:

1. **Write Model**: Create model file in checker's format
2. **Specify Properties**: Define properties to verify
3. **Run Checker**: Execute from command line or via keybinding
4. **Review Results**: Check output for verification results

**Example Workflow** (using MLSolver):
```bash
# Create modal formula file
nvim formula.ml

# Run MLSolver
:!mlsolver formula.ml

# Review output
# - SATISFIABLE: Model found
# - UNSATISFIABLE: No model exists
```

### Modal Logic Example

**Formula File** (`formula.ml`):
```
# K axiom: □(A → B) → (□A → □B)
box(imp(A, B)) -> imp(box(A), box(B))

# Check satisfiability
SAT
```

**Verification**:
```vim
:!mlsolver %
```

Output indicates whether formula is satisfiable and provides model if found.

### Custom Verification Scripts

Create shell scripts for common verification tasks:

**Example** (`verify.sh`):
```bash
#!/bin/bash
# Verify modal logic formula

MODEL_FILE="$1"
CHECKER="mlsolver"

if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: File $MODEL_FILE not found"
    exit 1
fi

echo "Verifying: $MODEL_FILE"
$CHECKER "$MODEL_FILE"
```

**Usage in NeoVim**:
```vim
:!./verify.sh %
```

## Formal Methods Workflow

### Theorem Proving Workflow

1. **Formalize Problem**
   - Translate mathematical concepts to Lean
   - Define types, structures, and properties
   - State theorems precisely

2. **Develop Proof**
   - Use tactics to transform goals
   - Check Infoview for proof state
   - Build proof incrementally

3. **Verify Proof**
   - Lean checks proof automatically
   - LSP shows errors immediately
   - Fix issues as they appear

4. **Document Proof**
   - Add comments explaining strategy
   - Reference related theorems
   - Provide intuition for tactics

### Model Checking Workflow

1. **Create Model**
   - Write model in checker's language
   - Define states and transitions
   - Specify initial conditions

2. **Specify Properties**
   - Express desired properties formally
   - Use temporal logic operators
   - Consider edge cases

3. **Run Verification**
   - Execute model checker
   - Review verification results
   - Examine counterexamples if found

4. **Refine Model**
   - Fix issues revealed by checking
   - Strengthen properties if needed
   - Re-verify after changes

## LSP Configuration

### Lean LSP

The Lean 4 language server provides:
- **Type information**: Hover for type details
- **Go to definition**: Navigate to definitions
- **Find references**: Find all uses
- **Diagnostics**: Errors and warnings
- **Completion**: Tactics, theorems, definitions

**Configuration**: Automatic when `lean.nvim` plugin loaded

**Commands**:
- `:LeanInfoviewEnable` - Show infoview
- `:LeanInfoviewDisable` - Hide infoview
- `:LeanRestartServer` - Restart Lean LSP

### Custom LSP for Model Checkers

Most model-checkers don't have LSP servers. Integration is via:
- **External commands**: Run checker on current file
- **QuickFix list**: Parse errors into quickfix
- **Terminal**: Run checker in terminal split

## Project Examples

### Mathematical Formalization Project

**Structure**:
```
FormalMath/
├── lakefile.lean
├── lean-toolchain
├── FormalMath/
│   ├── Algebra/
│   │   ├── Groups.lean
│   │   └── Rings.lean
│   ├── Analysis/
│   │   └── Limits.lean
│   └── NumberTheory/
│       └── Primes.lean
└── FormalMath.lean
```

**Workflow**:
1. Open file: `nvim FormalMath/Algebra/Groups.lean`
2. Edit definitions and proofs
3. Infoview shows real-time verification
4. Build project: `lake build` (in terminal)

### Philosophy Argument Verification

**Structure**:
```
ArgumentAnalysis/
├── models/
│   ├── argument1.ml
│   └── argument2.ml
├── verification/
│   └── verify.sh
└── results/
    └── results.md
```

**Workflow**:
1. Create model: `nvim models/argument1.ml`
2. Write formal argument structure
3. Run verification: `:!./verification/verify.sh %`
4. Document results: Update `results/results.md`

## Resources and Learning

### Lean 4 Resources

**Official Documentation**:
- Lean 4 Manual: https://lean-lang.org/lean4/doc/
- Theorem Proving in Lean: https://lean-lang.org/theorem_proving_in_lean4/
- Mathlib Documentation: https://leanprover-community.github.io/mathlib4_docs/

**Community**:
- Lean Zulip Chat: https://leanprover.zulipchat.com/
- Lean GitHub: https://github.com/leanprover/lean4

### Model-Checking Resources

**Tools**:
- MLSolver: https://www2.tcs.ifi.lmu.de/~mlsolver/
- PRISM: https://www.prismmodelchecker.org/
- NuSMV: http://nusmv.fbk.eu/

**Tutorials**:
- Modal Logic: Stanford Encyclopedia of Philosophy
- Model Checking: Principles of Model Checking (book)

## Related Documentation

- [RESEARCH_TOOLING.md](RESEARCH_TOOLING.md) - Academic writing tools
- [Text Plugins README](../lua/neotex/plugins/text/README.md) - Plugin configurations
- [LSP Configuration](../lua/neotex/plugins/lsp/README.md) - LSP setup

## Notes

Formal verification integration provides:
- **Lean 4**: Interactive theorem proving with real-time feedback
- **Model Checking**: External tool integration for verification tasks
- **IDE Features**: LSP integration for Lean, syntax highlighting, Infoview

These tools support formal reasoning in mathematics and philosophy, enabling rigorous verification of proofs and arguments within the NeoVim environment.

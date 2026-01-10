# Logos Project Context

## Project Overview

**Logos** is a formal language of thought for AI reasoning, combining axiomatic proof theory (LEAN 4) with recursive semantic theory (Model-Checker) for dual verification of complex reasoning tasks.

**Purpose**: Train AI systems to conduct verified reasoning with explicit semantic models, supporting planning and action evaluation under uncertainty.

**Repository**: ProofChecker (historical name, now "Logos")

## Technology Stack

**Primary Language:** LEAN 4 (v4.14.0)
**Build System:** Lake (LEAN package manager)
**Dependencies:** mathlib4 (v4.14.0)
**Testing:** Custom test suite in LogosTest/
**Linting:** Custom LEAN linters (environment + style)
**Verification:** lean-lsp-mcp (Language Server Protocol integration)

## Project Structure

```
Logos/                      # Main library
├── Core/                   # Core bimodal logic (TM)
│   ├── Syntax/            # Formula definitions, contexts
│   ├── ProofSystem/       # Axioms, derivation rules
│   ├── Semantics/         # Task frames, models, truth, validity
│   ├── Metalogic/         # Soundness, completeness, deduction theorem
│   ├── Theorems/          # Derived theorems (S4, S5, perpetuity, etc.)
│   └── Automation/        # Tactics, proof search, Aesop integration
├── Epistemic/             # Epistemic extensions
├── Explanatory/           # Explanatory extensions
├── Normative/             # Normative extensions
└── Lint/                  # Custom environment linters

LogosTest/                 # Test suite
├── Core/                  # Core layer tests
│   ├── Syntax/
│   ├── ProofSystem/
│   ├── Semantics/
│   ├── Metalogic/
│   ├── Theorems/
│   └── Automation/
└── Integration/           # End-to-end tests

Documentation/             # Project documentation
├── UserGuide/            # Tutorials, examples, integration
├── Development/          # Contributing, style guides, standards
├── ProjectInfo/          # Status, maintenance
├── Reference/            # Glossary, operators
└── Research/             # Theoretical foundations

.claude/               # AI agent system (current)
├── agent/                # Primary agents + specialists
├── command/              # Slash commands
├── context/              # Knowledge base for agents
└── specs/                # Project artifacts (plans, reports)
```

## Core Architecture

### Layered Operator System

**Core Layer (TM Bimodal Logic)**:
- Temporal operators: ◇ (possibility), □ (necessity)
- Modal operators: ◊ (metaphysical possibility), ■ (metaphysical necessity)
- Propositional connectives: ¬, ∧, ∨, →, ↔
- Kripke semantics: Task frames with world histories

**Extension Layers** (planned):
- Epistemic: Knowledge and belief operators
- Explanatory: Causal and counterfactual reasoning
- Normative: Deontic and evaluative operators

### Dual Verification Architecture

| Component | Implementation | Role | Training Signal |
|-----------|---------------|------|-----------------|
| **Proof System** | LEAN 4 (this repo) | Derives valid theorems | Positive RL signal |
| **Model-Checker** | Python (separate repo) | Finds countermodels | Corrective RL signal |

## Development Workflow

### Standard LEAN 4 Workflow

1. **Research**: Explore mathlib, existing proofs, literature
2. **Design**: Plan proof structure, identify lemmas
3. **Implementation**: Write LEAN 4 code with tactics/term-mode
4. **Verification**: Check with `lake build`, fix errors
5. **Testing**: Run test suite with `lake exe test`
6. **Documentation**: Update inline docs and Documentation/

### AI-Assisted Workflow

1. **Research**: `/research` - Multi-source research (LeanSearch, Loogle, web)
2. **Planning**: `/plan` - Create detailed implementation plans (sets `lean: true|false` in plan metadata)
3. **Implementation**: `/lean` - Implement Lean proofs with Lean specialists and multi-phase workflow
4. **Refactoring**: `/refactor` - Improve code quality and readability
5. **Documentation**: `/document` - Update documentation automatically
6. **Review**: `/review` - Analyze repository, verify proofs, identify tasks

See [.claude/README.md](../../README.md) for AI system details.

## Quality Standards

### LEAN 4 Code Quality

- **Style**: Follow [LEAN Style Guide](../../../Documentation/Development/LEAN_STYLE_GUIDE.md)
- **Proof Readability**: Clear tactic sequences, meaningful names
- **Documentation**: Inline doc comments for all public definitions
- **Testing**: Comprehensive test coverage in LogosTest/
- **No Sorries**: All proofs must be complete (tracked in SORRY_REGISTRY.md)

### Build Requirements

- `lake build` must succeed (no errors)
- `lake exe test` must pass all tests
- `lake exe lintAll` must pass (custom linters)
- `lake exe runEnvLinters` must pass (environment linters)
- `lake exe lintStyle` must pass (style linters)

### Documentation Standards

- Complete: All features documented
- Accurate: Docs match implementation
- Concise: No bloat or redundancy
- See [Documentation Standards](../lean4/standards/documentation-standards.md)

## Key Files

**Build Configuration**:
- `lakefile.lean` - Lake build configuration
- `lean-toolchain` - LEAN version (v4.14.0)
- `lake-manifest.json` - Dependency lock file

**Entry Points**:
- `Logos.lean` - Main library entry point
- `LogosTest.lean` - Test suite entry point
- `README.md` - Project overview

**Core Modules**:
- `Logos/Core/Syntax/Formula.lean` - Formula definitions
- `Logos/Core/ProofSystem/Axioms.lean` - Axiom system
- `Logos/Core/Semantics/Truth.lean` - Truth conditions
- `Logos/Core/Metalogic/Soundness.lean` - Soundness theorem
- `Logos/Core/Automation/Tactics.lean` - Custom tactics

## Common Commands

**Build & Test**:
```bash
lake build                    # Build entire project
lake build Logos             # Build main library only
lake exe test                # Run test suite
```

**Linting**:
```bash
lake exe lintAll             # Run all linters
lake exe runEnvLinters       # Run environment linters
lake exe lintStyle           # Run style linters
```

**Development**:
```bash
lake clean                   # Clean build artifacts
lake update                  # Update dependencies
```

**AI System**:
```bash
# See .claude/README.md for all AI commands
/research <topic>            # Research Lean libraries and literature
/plan <task>                 # Create implementation plan (records lean: true|false)
/lean <proof>                # Implement Lean 4 proof via Lean specialists
/implement <nums>                 # Execute tasks; Lean-tagged plans route to Lean implementation
/review                      # Analyze repository
```

## Project Status

**Current Phase**: Core Layer Implementation (TM Bimodal Logic)

**Completed**:
- [PASS] Syntax (Formula, Context)
- [PASS] Proof System (Axioms, Derivation)
- [PASS] Semantics (Task Frames, Truth, Validity)
- [PASS] Metalogic (Soundness, Completeness, Deduction Theorem)
- [PASS] Core Theorems (S4, S5, Perpetuity, Propositional)
- [PASS] Automation (Tactics MVP, Aesop Integration)
- [PASS] Test Suite (Comprehensive coverage)

**In Progress**:
- Proof Search (Infrastructure Ready)
- Extension layers (Epistemic, Explanatory, Normative)
- Advanced automation
- Integration with Model-Checker

See [IMPLEMENTATION_STATUS.md](../../../Documentation/ProjectInfo/IMPLEMENTATION_STATUS.md) for details.

## Related Resources

**Documentation**:
- [Project README](../../../README.md) - Overview and theoretical foundations
- [Architecture Guide](../../../Documentation/UserGuide/ARCHITECTURE.md) - System architecture
- [Tutorial](../../../Documentation/UserGuide/TUTORIAL.md) - Getting started
- [Examples](../../../Documentation/UserGuide/EXAMPLES.md) - Example proofs

**AI System**:
- [.claude/README.md](../../README.md) - AI system overview
- [.claude/ARCHITECTURE.md](../../ARCHITECTURE.md) - Agent system architecture
- [.claude/QUICK-START.md](../../QUICK-START.md) - AI workflow guide

**External**:
- [Model-Checker](https://github.com/benbrastmckie/ModelChecker) - Semantic verification
- [LogicNotes](https://github.com/benbrastmckie/LogicNotes) - Formal foundations
- [mathlib4](https://github.com/leanprover-community/mathlib4) - LEAN mathematics library
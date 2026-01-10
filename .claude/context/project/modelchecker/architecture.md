# ModelChecker Architecture

## Overview

ModelChecker is a framework for developing and exploring modular semantic theories using Z3 SMT solver. It provides automated countermodel generation, multiple model iteration, and theory comparison capabilities.

## Core Packages

### builder/
Coordinates the entire model checking workflow.

**Key Classes**:
- `BuildModule` - Main orchestrator, loads Python modules dynamically
- `ModelRunner` - Executes model checking operations
- `BuildExample` - Processes single examples
- `BuildProject` - Generates new theory projects
- `ModelComparison` - Benchmarks theories against each other

### iterate/
Finds multiple distinct models satisfying constraints.

**Key Classes**:
- `BaseModelIterator` - Abstract interface for iteration
- `IteratorCore` - Orchestrates iteration workflow
- `ConstraintGenerator` - Creates difference constraints
- `ModelBuilder` - Creates model structures from Z3 solutions
- `IsomorphismChecker` - Detects equivalent models via NetworkX

### theory_lib/
Contains semantic theory implementations.

**Theories**:
- `logos/` - Hyperintensional bilateral truthmaker semantics (20+ operators)
- `exclusion/` - Unilateral semantics (4 operators)
- `imposition/` - Kit Fine's counterfactual semantics (11 operators)
- `bimodal/` - Temporal-modal interaction (15 operators)

**Common Structure**:
```
{theory}/
├── semantic.py      # SemanticDefaults subclass
├── operators.py     # Operator definitions
├── examples.py      # Test cases
├── iterate.py       # Theory-specific iteration
├── __init__.py      # get_theory(), get_examples()
└── tests/           # Unit/integration tests
```

### models/
Core model structures for semantic evaluation.

**Key Classes**:
- `SemanticDefaults` - Base evaluation framework
- `PropositionDefaults` - Proposition management
- `ModelConstraints` - Z3 constraint generation
- `ModelDefaults` - Complete model checking workflow

### syntactic/
Logical formula processing.

**Key Classes**:
- `Sentence` - Formula representation
- `OperatorCollection` - Operator registry
- `Operator` / `DefinedOperator` - Base classes
- `AtomSort` - Z3 atomic propositions

### settings/
Configuration management with priority hierarchy.

**Priority Order**:
1. CLI flags (highest)
2. Example settings
3. User preferences
4. Theory defaults
5. Global defaults (lowest)

### output/
Result formatting in multiple formats.

**Formats**:
- Markdown documentation
- JSON data export
- Jupyter notebook generation

## Data Flow

```
User Input (Python module)
    │
    ▼
BuildModule (loads module, validates settings)
    │
    ▼
ModelRunner (coordinates execution)
    │
    ├─► BuildExample (per example)
    │       │
    │       ▼
    │   Theory Semantic (generates Z3 constraints)
    │       │
    │       ▼
    │   Z3 Solver (finds model/countermodel)
    │       │
    │       ▼
    │   ModelIterator (finds additional models if requested)
    │
    ▼
OutputManager (formats results)
```

## Z3 Integration

### Constraint Generation
Theories define semantic clauses that generate Z3 constraints:

```python
def operator_verifier(self, sentence, eval_world):
    """Generate Z3 constraint for verifier clause."""
    left = self.true_at(sentence.arguments[0], eval_world)
    right = self.true_at(sentence.arguments[1], eval_world)
    return z3.And(left, right)
```

### Solver Management
- One solver per example
- Timeout enforcement (default 10s)
- Incremental solving for iteration

### State Space
- BitVector representation for worlds/states
- N parameter controls bitwidth (default 3 = 8 states)
- Constraints ensure well-formed models

## Theory Extension Points

### Adding New Theory
1. Create directory in `theory_lib/`
2. Implement `SemanticDefaults` subclass
3. Register operators in `operators.py`
4. Add examples in `examples.py`
5. Register in `theory_lib/__init__.py`

### Adding New Operator
1. Add semantic clauses in `semantic.py`
2. Register in `operators.py`
3. Add test examples

### Adding New Setting
1. Add to `DEFAULT_EXAMPLE_SETTINGS`
2. Add validation in settings package
3. Document in theory docs

## Key Design Decisions

### Relative Imports
Package uses relative imports within modules for portability.

### No Backwards Compatibility
Clean breaks when improving - no compatibility layers.

### Fail-Fast
Early validation with clear error messages.

### Explicit Data Flow
No hidden state or implicit conversions.

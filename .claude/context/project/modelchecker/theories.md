# Semantic Theory Library

## Overview

The theory library contains four semantic theories, each implementing a different approach to truthmaker semantics or modal logic.

## Logos Theory

**Purpose**: Hyperintensional bilateral truthmaker semantics

**Operators**: 20+ across 5 subtheories

### Subtheories

#### Extensional (7 operators)
Basic propositional connectives:
- `neg` (¬) - Negation
- `wedge` (∧) - Conjunction
- `vee` (∨) - Disjunction
- `rightarrow` (→) - Material conditional
- `leftrightarrow` (↔) - Biconditional
- `top` (⊤) - Tautology
- `bot` (⊥) - Contradiction

#### Modal (4 operators)
Necessity and possibility:
- `Box` (□) - Necessity
- `Diamond` (◇) - Possibility
- `boxmark` (■) - Ground necessity
- `diamondmark` (◆) - Ground possibility

#### Constitutive (5 operators)
Content and grounding relations:
- `sqsubseteq` (⊑) - Content part
- `equiv` (≡) - Content identity
- `preceq` (⪯) - Ground
- `prec` (≺) - Strict ground
- `leq` (≤) - Essence

#### Counterfactual (2 operators)
Would/might counterfactuals:
- `boxright` (□→) - Would counterfactual
- `circright` (◯→) - Might counterfactual

#### Relevance (1 operator)
- `implicates` - Relevant implication

### Usage

```python
from model_checker.theory_lib.logos import get_theory, get_examples

theory = get_theory()
examples = get_examples()
```

### Selective Loading

```python
# Load only specific subtheories
from model_checker import BuildModule

module = BuildModule(
    path='my_examples.py',
    theory='logos',
    subtheory='counterfactual'  # Loads extensional + counterfactual
)
```

## Exclusion Theory

**Purpose**: Unilateral semantics with witness predicates

**Operators**: 4
- `barwedge` (⩞) - Exclusive disjunction
- `neg` (¬) - Negation
- `wedge` (∧) - Conjunction
- `vee` (∨) - Disjunction

**Unique Feature**: Witness predicates for exclusion

### Usage

```python
from model_checker.theory_lib.exclusion import get_theory, get_examples

theory = get_theory()
examples = get_examples()  # 38 examples
```

## Imposition Theory

**Purpose**: Kit Fine's counterfactual semantics

**Operators**: 11
- Standard propositional operators
- `boxright` (□→) - Would counterfactual
- `circright` (◯→) - Might counterfactual
- `imposition` operators for state relations

**Unique Feature**: Primitive imposition relations on states

### Usage

```python
from model_checker.theory_lib.imposition import get_theory, get_examples

theory = get_theory()
examples = get_examples()  # 120 examples
```

## Bimodal Theory

**Purpose**: Temporal-modal interaction

**Status**: Under development

**Operators**: 15
- Modal operators (Box, Diamond)
- Temporal operators (Always, Eventually, Until)
- Interaction operators

**Unique Feature**: World history semantics with lawful transitions

### Usage

```python
from model_checker.theory_lib.bimodal import get_theory, get_examples

theory = get_theory()
examples = get_examples()  # 22 examples
```

## Common Patterns

### Theory Structure

All theories follow this structure:

```python
# semantic.py
class TheorySemantics(SemanticDefaults):
    DEFAULT_EXAMPLE_SETTINGS = {
        'N': 3,
        'contingent': False,
        'non_empty': False,
        'max_time': 10,
    }

    def operator_verifier(self, sentence, eval_world):
        """Verifier clause."""
        ...

    def operator_falsifier(self, sentence, eval_world):
        """Falsifier clause."""
        ...
```

```python
# operators.py
def get_operators():
    return OperatorCollection([
        Operator(
            name='op_name',
            symbol='◊',
            verifier=semantic.op_verifier,
            falsifier=semantic.op_falsifier,
            arity=1,
            precedence=5,
        ),
    ])
```

```python
# __init__.py
def get_theory():
    """Get theory instance."""
    ...

def get_examples():
    """Get example list."""
    ...
```

### Settings

Common settings across theories:

| Setting | Default | Description |
|---------|---------|-------------|
| `N` | 3 | State space size (2^N states) |
| `contingent` | False | Force all propositions contingent |
| `non_empty` | False | Non-empty verifier/falsifier sets |
| `non_null` | False | Allow null state |
| `disjoint` | False | Disjoint verifier/falsifier sets |
| `max_time` | 10 | Z3 timeout in seconds |
| `iterate` | 1 | Number of models to find |

### Examples

Example definition pattern:

```python
BuildExample(
    name='test_conjunction',
    premises=['A wedge B'],
    conclusions=['A', 'B'],
    settings={'N': 3},
    expectation=True,  # Expect valid
)
```

## Theory Comparison

Use `--maximize` flag to compare theories:

```bash
model-checker examples.py --maximize
```

This finds the maximum N value each theory can handle for given constraints.

## Adding a New Theory

1. Create `theory_lib/newtheory/`
2. Implement required files:
   - `semantic.py` - SemanticDefaults subclass
   - `operators.py` - Operator definitions
   - `examples.py` - Test examples
   - `iterate.py` - Iteration support (optional)
   - `__init__.py` - Public API

3. Register in `theory_lib/__init__.py`:
   ```python
   THEORIES['newtheory'] = 'model_checker.theory_lib.newtheory'
   ```

4. Add tests in `tests/`

5. Document in `docs/`

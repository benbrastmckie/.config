# Z3 Solver Patterns for ModelChecker

## Overview

ModelChecker uses Z3 SMT solver for satisfiability checking, model generation, and constraint solving. This document covers common patterns and best practices.

## Basic Solver Usage

### Creating and Using Solvers

```python
import z3

# Create solver
solver = z3.Solver()

# Set timeout (milliseconds)
solver.set("timeout", 10000)  # 10 seconds

# Add constraints
solver.add(constraint1)
solver.add(constraint2)

# Check satisfiability
result = solver.check()

if result == z3.sat:
    model = solver.model()
    # Extract values from model
elif result == z3.unsat:
    # No solution exists
    pass
else:  # z3.unknown
    # Timeout or inconclusive
    pass
```

### Incremental Solving

```python
solver = z3.Solver()
solver.add(base_constraints)

# Save state
solver.push()
solver.add(additional_constraints)
result = solver.check()
solver.pop()  # Restore state

# Can now try different additional constraints
```

## Variable Types

### Boolean Variables

```python
# Single boolean
p = z3.Bool('p')
q = z3.Bool('q')

# Boolean array
props = [z3.Bool(f'p_{i}') for i in range(n)]
```

### BitVectors (for states/worlds)

```python
# Create BitVector of width N
world = z3.BitVec('w', 3)  # 3-bit = 8 possible values

# BitVector operations
combined = world | other_world  # Union
both = world & other_world      # Intersection
empty = z3.BitVecVal(0, 3)      # Empty set
full = z3.BitVecVal(7, 3)       # Full set (2^3 - 1)
```

### Functions

```python
# Uninterpreted function
verify = z3.Function('verify', z3.BitVecSort(3), z3.BoolSort())

# Using function
constraint = verify(world) == True
```

## Constraint Patterns

### Propositional Constraints

```python
# Basic connectives
conjunction = z3.And(p, q)
disjunction = z3.Or(p, q)
negation = z3.Not(p)
implication = z3.Implies(p, q)
biconditional = p == q
```

### Quantified Constraints

```python
# Universal quantification
x = z3.BitVec('x', 3)
forall = z3.ForAll([x], condition(x))

# Existential quantification
exists = z3.Exists([x], condition(x))

# With patterns for efficiency
forall_pattern = z3.ForAll(
    [x],
    condition(x),
    patterns=[trigger_pattern]
)
```

### Set Operations with BitVectors

```python
# State as BitVector
state = z3.BitVec('s', 3)

# Check if state in set (represented as int)
state_set = z3.BitVecVal(5, 3)  # Binary: 101 = states 0 and 2
in_set = (state & state_set) != z3.BitVecVal(0, 3)

# Part-of relation
is_part_of = (state & other) == state

# Fusion (join)
fusion = state | other
```

## Model Extraction

### Getting Values

```python
if solver.check() == z3.sat:
    model = solver.model()

    # Boolean value
    p_val = model.eval(p, model_completion=True)
    is_true = z3.is_true(p_val)

    # BitVector value
    w_val = model.eval(world, model_completion=True)
    if isinstance(w_val, z3.BitVecNumRef):
        w_int = w_val.as_long()

    # Function interpretation
    func_interp = model.get_interp(verify)
```

### Iterating Over Variables

```python
model = solver.model()
for decl in model.decls():
    name = decl.name()
    value = model[decl]
    print(f"{name} = {value}")
```

## Semantic Clause Patterns

### Verifier Clause

```python
def conjunction_verifier(self, sentence, eval_world):
    """
    Verifier for conjunction: A ∧ B is verified iff
    both A and B are verified.
    """
    left = sentence.arguments[0]
    right = sentence.arguments[1]

    left_ver = self.true_at(left, eval_world)
    right_ver = self.true_at(right, eval_world)

    return z3.And(left_ver, right_ver)
```

### Falsifier Clause

```python
def conjunction_falsifier(self, sentence, eval_world):
    """
    Falsifier for conjunction: A ∧ B is falsified iff
    either A or B is falsified.
    """
    left = sentence.arguments[0]
    right = sentence.arguments[1]

    left_fal = self.false_at(left, eval_world)
    right_fal = self.false_at(right, eval_world)

    return z3.Or(left_fal, right_fal)
```

### Modal Operator

```python
def necessity_verifier(self, sentence, eval_world):
    """
    Verifier for necessity: □A is verified at w iff
    A is verified at all accessible worlds.
    """
    inner = sentence.arguments[0]

    # Quantify over all worlds
    w = z3.BitVec('w', self.N)

    return z3.ForAll(
        [w],
        z3.Implies(
            self.accessible(eval_world, w),
            self.true_at(inner, w)
        )
    )
```

## Performance Optimization

### Minimize Constraint Count

```python
# Bad: Many small constraints
for i in range(n):
    solver.add(condition(i))

# Good: Single combined constraint
solver.add(z3.And([condition(i) for i in range(n)]))
```

### Use Simplification

```python
# Simplify before adding
simplified = z3.simplify(complex_constraint)
solver.add(simplified)
```

### Efficient Quantifiers

```python
# Add patterns for quantifier instantiation
x = z3.BitVec('x', 3)
pattern = z3.BitVec('pattern', 3)

constraint = z3.ForAll(
    [x],
    z3.Implies(condition(x), result(x)),
    patterns=[condition(x)]  # Pattern hint
)
```

### Incremental Solving for Iteration

```python
# For finding multiple models
solver = z3.Solver()
solver.add(base_constraints)

models = []
while len(models) < max_models:
    if solver.check() == z3.sat:
        model = solver.model()
        models.append(model)

        # Add constraint excluding this model
        solver.add(z3.Or([
            v != model.eval(v) for v in variables
        ]))
    else:
        break
```

## Error Handling

### Common Z3 Errors

```python
try:
    result = solver.check()
except z3.Z3Exception as e:
    if "timeout" in str(e):
        # Handle timeout
        pass
    else:
        raise
```

### Type Checking

```python
# Ensure type compatibility
assert p.sort() == z3.BoolSort()
assert world.sort() == z3.BitVecSort(3)

# Check before operations
if z3.is_bv(x) and z3.is_bv(y):
    result = x | y
```

## Context Management

### Isolated Contexts

```python
# Each example uses fresh context
ctx = z3.Context()
solver = z3.Solver(ctx=ctx)
p = z3.Bool('p', ctx=ctx)
```

### Resource Cleanup

```python
# Explicit cleanup if needed
del solver
import gc
gc.collect()
```

## Debugging

### Print Constraints

```python
print("Constraints:")
for c in solver.assertions():
    print(f"  {c}")
```

### Check Unsatisfiable Core

```python
solver = z3.Solver()
solver.set("unsat_core", True)

# Track constraints
p1 = z3.Bool('p1')
solver.assert_and_track(constraint1, p1)

if solver.check() == z3.unsat:
    core = solver.unsat_core()
    print("Unsat core:", core)
```

### Model Validation

```python
if solver.check() == z3.sat:
    model = solver.model()

    # Verify model satisfies all constraints
    for c in solver.assertions():
        val = model.eval(c, model_completion=True)
        assert z3.is_true(val), f"Failed: {c}"
```

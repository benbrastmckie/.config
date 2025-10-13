# Parallel Execution Example Plan

This is an example implementation plan demonstrating parallel phase execution using dependency declarations.

## Overview

This plan shows how to structure phases with dependencies to enable parallel execution:
- Phase 1 runs first (no dependencies)
- Phases 2 and 3 run in parallel (both depend only on Phase 1)
- Phase 4 runs last (depends on both Phase 2 and 3)

## Execution Flow

```
Phase 1 (Setup)
    |
    ├────> Phase 2 (Module A)  ┐
    |                           ├──> Phase 4 (Integration)
    └────> Phase 3 (Module B)  ┘

Wave 1: Phase 1
Wave 2: Phases 2 and 3 (parallel)
Wave 3: Phase 4
```

## Metadata

- **Plan**: Example parallel execution plan
- **Total Phases**: 4
- **Parallel Phases**: 2 (Phases 2 and 3)
- **Expected Speedup**: 30-40% faster than sequential execution

## Success Criteria

- [ ] All phases complete successfully
- [ ] Phases 2 and 3 execute in parallel
- [ ] Phase 4 waits for both 2 and 3 to complete
- [ ] Tests pass for all modules
- [ ] Integration successful

## Implementation Phases

### Phase 1: Project Setup
dependencies: []

**Objective**: Initialize project structure and dependencies

Tasks:
- [ ] Create project directory structure
- [ ] Initialize package manager (npm/pip/cargo)
- [ ] Set up configuration files
- [ ] Install base dependencies
- [ ] Create README and documentation skeleton

Testing:
```bash
# Verify project structure
ls -la
# Check package installation
npm list / pip list / cargo check
```

### Phase 2: Implement Module A
dependencies: [1]

**Objective**: Build Module A functionality

Tasks:
- [ ] Create module A source files
- [ ] Implement core functionality for Module A
- [ ] Add unit tests for Module A
- [ ] Document Module A API
- [ ] Run Module A tests

Testing:
```bash
# Run Module A tests
npm test src/module-a/
# Or: pytest tests/test_module_a.py
```

### Phase 3: Implement Module B
dependencies: [1]

**Objective**: Build Module B functionality (independent of Module A)

Tasks:
- [ ] Create module B source files
- [ ] Implement core functionality for Module B
- [ ] Add unit tests for Module B
- [ ] Document Module B API
- [ ] Run Module B tests

Testing:
```bash
# Run Module B tests
npm test src/module-b/
# Or: pytest tests/test_module_b.py
```

**Note**: Phase 3 can run in parallel with Phase 2 because they're independent.

### Phase 4: Integration and System Tests
dependencies: [2, 3]

**Objective**: Integrate modules A and B and test the complete system

Tasks:
- [ ] Create integration layer
- [ ] Connect Module A and Module B
- [ ] Add integration tests
- [ ] Run full test suite
- [ ] Update documentation with integration examples
- [ ] Verify system meets success criteria

Testing:
```bash
# Run integration tests
npm test tests/integration/
# Or: pytest tests/integration/

# Run full test suite
npm test
```

## Key Points for Parallel Execution

**Dependency Declaration**:
- Use `dependencies: []` for phases with no dependencies (runs in first wave)
- Use `dependencies: [1]` for phases depending on Phase 1
- Use `dependencies: [2, 3]` for phases depending on multiple phases

**Parallel Safety**:
- Ensure parallel phases don't modify the same files
- Each phase should be independent and not interfere with others
- Test each module in isolation before integration

**Error Handling**:
- If Phase 2 or 3 fails, Phase 4 won't run
- Failed phases can be fixed and resumed
- Checkpoint is saved after each wave

**Performance Benefits**:
- Traditional execution: Phase 1 (5m) → Phase 2 (10m) → Phase 3 (10m) → Phase 4 (5m) = 30m total
- Parallel execution: Phase 1 (5m) → [Phase 2 + 3 in parallel] (10m) → Phase 4 (5m) = 20m total
- Speedup: 33% faster (10 minutes saved)

## Related Documentation

- [Implementation Command](../commands/implement.md) - Full /implement documentation
- [Dependency Parser](../utils/parse-phase-dependencies.sh) - Utility for parsing dependencies
- [Plan Format](../commands/plan.md) - Standard plan format

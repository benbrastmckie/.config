# Wave Execution Test Fixtures

Test fixtures for wave-based parallel execution and dependency analysis.

## Purpose

This directory contains plan fixtures with various dependency patterns used to verify the dependency analyzer and wave-based execution coordinator. Tests ensure correct wave assignment, parallel execution opportunities, and dependency constraint satisfaction.

## Files in This Directory

### linear_plan.md
**Purpose**: Plan with linear sequential dependencies
**Test Coverage**: Sequential wave execution validation
**Structure**: 3+ phases with linear dependency chain (1→2→3)

### fan_out_plan.md
**Purpose**: Plan with independent parallel phases
**Test Coverage**: Parallel wave execution validation
**Structure**: 1 setup phase → multiple independent phases

### diamond_plan.md
**Purpose**: Plan with diamond dependency pattern
**Test Coverage**: Wave synchronization and dependency merging
**Structure**: Phase 1 → (Phase 2, Phase 3) → Phase 4

### circular_plan.md
**Purpose**: Plan with circular dependency (invalid)
**Test Coverage**: Circular dependency detection
**Structure**: Phases with cycle (A→B→C→A)

### invalid_dependency_plan.md
**Purpose**: Plan with nonexistent phase references
**Test Coverage**: Dependency validation and error reporting
**Structure**: Phases referencing undefined dependencies

## Navigation

- [← Parent Directory](../README.md)
- [Related: orchestrate_e2e/](../orchestrate_e2e/README.md)

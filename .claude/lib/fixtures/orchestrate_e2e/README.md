# End-to-End Orchestration Test Fixtures

Test fixtures for comprehensive orchestration system validation.

## Purpose

This directory contains test plans and phase files used for end-to-end testing of the plan orchestration system. Fixtures cover consistency, cross-referencing, expansion, and hierarchical structure scenarios to ensure robust orchestration behavior.

## Subdirectories

### [test_consistency/](test_consistency/README.md)
Minimal plan fixtures for consistency verification across multiple parsing operations.

### [test_cross_ref/](test_cross_ref/README.md)
Plan fixtures with cross-referenced phases and dependencies for referential integrity testing.

### [test_expansion/](test_expansion/README.md)
Compact plan fixtures for progressive expansion testing (Level 0 → Level 1 → Level 2).

### [test_hierarchy/](test_hierarchy/README.md)
Plan fixtures with hierarchical phase structures for multi-level parsing validation.

## Files in This Directory

### test_circular.md
**Purpose**: Plan with circular dependencies (invalid case)
**Test Coverage**: Circular dependency detection
**Structure**: Invalid dependency cycle

### test_complexity_plan.md
**Purpose**: Complex multi-phase plan for integration testing
**Test Coverage**: Complex orchestration scenarios
**Structure**: Multiple phases with varied dependencies

### test_dependencies.md
**Purpose**: Plan with explicit dependency declarations
**Test Coverage**: Dependency parsing and validation
**Structure**: Phases with dependency: [] metadata

### test_expansion.md
**Purpose**: Root-level expansion test plan
**Test Coverage**: Plan expansion system
**Structure**: Compact plan suitable for expansion

## Navigation

- [← Parent Directory](../README.md)
- [Related: wave_execution/](../wave_execution/README.md)

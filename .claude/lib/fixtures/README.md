# Test Fixtures

Test plan fixtures for orchestration and parsing system validation.

## Purpose

This directory contains test fixtures organized by orchestration feature area. Fixtures include minimal plans, complex dependency graphs, and edge cases used to verify plan parsing, expansion, dependency analysis, and wave-based execution.

## Subdirectories

### [orchestrate_e2e/](orchestrate_e2e/README.md)
End-to-end orchestration test fixtures including consistency, cross-reference, expansion, and hierarchy tests. Contains both root-level plans and expanded phase files for comprehensive testing.

### [wave_execution/](wave_execution/README.md)
Wave-based execution test fixtures with various dependency patterns (linear, fan-out, diamond, circular, invalid) for dependency analyzer and parallel execution validation.

## Navigation

- [← Parent Directory](../README.md)
- [Related: test_data/](../test_data/README.md)

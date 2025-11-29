# Consistency Test Fixtures

Test fixtures for plan parsing and orchestration consistency validation.

## Purpose

This directory contains minimal plan fixtures used to verify consistent parsing and state management across multiple reads of the same plan. Tests ensure that plan structure, phase definitions, and task metadata remain stable across parsing operations.

## Files in This Directory

### test_consistency.md
**Purpose**: Minimal single-phase plan for consistency verification
**Test Coverage**: Plan parsing consistency tests
**Structure**: 1 phase, 1 task, no dependencies

### phase_1_test.md
**Purpose**: Expanded phase file for multi-file consistency testing
**Test Coverage**: Phase-level parsing consistency
**Structure**: Phase fragment for expanded plan testing

## Navigation

- [← Parent Directory](../README.md)
- [Related: test_expansion/](../test_expansion/README.md)

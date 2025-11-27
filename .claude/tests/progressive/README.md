# Progressive Expansion Tests

Tests for plan expansion and collapse functionality.

## Purpose

This directory contains tests that verify the progressive plan organization
system works correctly, including phase/stage expansion, collapse operations,
and hierarchy management.

## Test Files

| File | Description |
|------|-------------|
| `test_hierarchy_updates.sh` | Test hierarchy update operations |
| `test_parallel_collapse.sh` | Test parallel collapse operations |
| `test_parallel_expansion.sh` | Test parallel expansion operations |
| `test_plan_progress_markers.sh` | Test progress marker handling |
| `test_plan_updates.sh` | Test plan file updates |
| `test_progressive_collapse.sh` | Test collapse from expanded state |
| `test_progressive_expansion.sh` | Test expansion from Level 0 |
| `test_progressive_roundtrip.sh` | Test expand then collapse |

## Running Tests

```bash
# Run all progressive tests
./run_all_tests.sh --category progressive

# Run a specific test
bash tests/progressive/test_progressive_expansion.sh
```

## Plan Levels

- Level 0: Single file with all phases inline
- Level 1: Phase files in plan subdirectory
- Level 2: Stage files in phase subdirectories

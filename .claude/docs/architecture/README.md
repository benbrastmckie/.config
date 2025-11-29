# Architecture Documentation

Comprehensive system architecture documentation and technical deep-dives.

## Purpose

This directory contains detailed architectural overviews for major system components and patterns. Architecture files are expected to be comprehensive (>500 lines acceptable) as they serve as single source of truth for complex designs.

## Files

### State-Based Orchestration
- [state-based-orchestration-overview.md](state-based-orchestration-overview.md) - Complete state machine architecture (2,000+ lines)
  - Architecture principles and design decisions
  - State machine design and selective persistence patterns
  - Hierarchical supervisor coordination
  - Performance characteristics and benchmarks
  - Production-ready implementation status

- [workflow-state-machine.md](workflow-state-machine.md) - State machine library design and API
  - 8 explicit states with validated transitions
  - Transition table and atomic state operations
  - Checkpoint coordination
  - 50 comprehensive tests (100% pass rate)

- [coordinate-state-management.md](coordinate-state-management.md) - /coordinate subprocess isolation patterns
  - Bash block execution model and subprocess isolation
  - State persistence and cross-block state management
  - Save-before-source pattern and library re-sourcing
  - Decision matrix for state management strategies
  - 100% reliability (zero unbound variables/verification failures)

- [hierarchical-supervisor-coordination.md](hierarchical-supervisor-coordination.md) - Multi-level supervisor design
  - Research supervisor: 95.6% context reduction
  - Implementation supervisor: 53% time savings
  - Testing supervisor: Sequential lifecycle coordination
  - 19 comprehensive tests (100% pass rate)

## When to Add Files

Add architecture documentation when:
- Introducing new system-level architectural patterns
- Documenting complex component interactions
- Creating comprehensive technical reference (>500 lines justified)
- Unifying multiple related design decisions

## Navigation

- [← Parent Directory](../README.md)
- [Related: Concepts](../concepts/README.md)
- [Related: Reference](../reference/README.md)

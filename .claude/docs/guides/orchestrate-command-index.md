# /orchestrate Command Guide - Index

This guide has been split into 2 files for easier navigation.

## Quick Navigation

### [Part 1: Overview & Architecture](orchestrate-overview-architecture.md)
**Lines: 800** | **Topics**: Purpose, syntax, architecture, workflow infrastructure

- Overview and Purpose
- When to Use / NOT to Use
- Key Features
- Command Syntax
- Architecture
  - Role: Workflow Orchestrator
  - Architectural Pattern
  - Critical Architectural Warnings
  - Tools
- Workflow Infrastructure
  - TodoWrite Initialization
  - Workflow State Structure
  - Shared Utilities Integration
  - Error Handling Strategy
  - Progress Streaming
- Phase 0: Location Determination

### [Part 2: Phases & Implementation](orchestrate-phases-implementation.md)
**Lines: 754** | **Topics**: Phase execution, examples, troubleshooting

- Detailed Phase Implementation
- Phase-by-Phase Workflows
- Agent Delegation Patterns
- Examples and Case Studies
- Troubleshooting Guide
- Common Issues and Solutions

## Related Documentation

- [/orchestrate Command](../../commands/orchestrate.md) - Executable command file
- [Orchestration Best Practices](orchestration-best-practices.md)
- [State-Based Orchestration](../architecture/state-based-orchestration-overview.md)
- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md)

## Migration Note

This guide was split from a single 1,546-line file into 2 manageable files in November 2025. The original file has been preserved for reference as `orchestrate-command-guide.md` but is deprecated.

---

**Total Lines**: 1,554 (split files) + 50 (index) = 1,604 lines
**Original File**: 1,546 lines
**Size Reduction**: Both split files are <900 lines (well under 400-line bloat threshold)

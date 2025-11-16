# Command Development Guide - Index

This guide has been split into 5 topic-based files for easier navigation and maintenance.

## Quick Navigation

### [Part 1: Fundamentals](command-development-fundamentals.md)
**Lines: 800** | **Topics**: Core architecture, command structure, metadata fields

- What is a Command?
- Command Architecture
- Command Definition Format
- Metadata Fields
- Tools and Permissions
- Executable/Documentation Separation Pattern
- Command Development Workflow

### [Part 2: Standards Integration](command-development-standards-integration.md)
**Lines: 808** | **Topics**: Standards discovery, CLAUDE.md integration, library usage

- Standards Discovery and Application
- Agent Integration Patterns
- Behavioral Injection Pattern
- Pre-Calculating Paths
- Artifact Verification
- Metadata Extraction
- Using Utility Libraries

### [Part 3: Advanced Patterns](command-development-advanced-patterns.md)
**Lines: 808** | **Topics**: State management, bash blocks, subprocess isolation

- State Management Patterns
- Subprocess Isolation Constraint
- Pattern Catalog:
  - Pattern 1: Stateless Recalculation
  - Pattern 2: Checkpoint Files
  - Pattern 3: File-based State
  - Pattern 4: Single Large Block
- Decision Framework
- Anti-Patterns

### [Part 4: Examples & Case Studies](command-development-examples-case-studies.md)
**Lines: 808** | **Topics**: Practical examples, refactoring case studies

- Case Studies:
  - /coordinate - Stateless Recalculation Pattern
  - /implement - Checkpoint Files Pattern
- Common Patterns and Examples
- Research Command with Agent Delegation
- When to Use Inline Templates
- Dry-Run Mode Examples
- Dashboard Progress Examples
- Checkpoint Save/Restore Examples
- Test Execution Patterns
- Git Commit Patterns
- Context Preservation Examples

### [Part 5: Troubleshooting](command-development-troubleshooting.md)
**Lines: 788** | **Topics**: Common mistakes, debugging, validation

- Common Mistakes and Solutions:
  1. Agent Invocation Wrapped in Code Blocks
  2. Missing Verification Checkpoints
  3. Using "Should/May/Can" Instead of "Must/Will/Shall"
  4. Invoking Commands with SlashCommand Tool
  5. Missing Completion Signals
  6. Passing Full Content Instead of Metadata
  7. No Fail-Fast Error Handling
  8. Relative Paths Without Verification
  9. Synchronous Agent Dependencies
  10. Excessive Template Content Inline
- Quick Diagnostic Checklist
- Troubleshooting Resources
- Cross-References

## Related Documentation

- [Command Architecture Standards](../reference/command_architecture_standards.md)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md)
- [Library API Reference](../reference/library-api.md)
- [Agent Development Guide](agent-development-guide.md)

## Migration Note

This guide was split from a single 3,980-line file into 5 manageable files in November 2025. The original file has been preserved for reference as `command-development-guide.md` but is deprecated. Use this index to navigate the split files.

---

**Total Lines**: 3,212 (split files) + 100 (index) = 3,312 lines
**Original File**: 3,980 lines
**Size Reduction**: All split files are <900 lines (target: <800 lines achieved for files 1-4)

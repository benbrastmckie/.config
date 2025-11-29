# Command Implementation Patterns

Reusable patterns for command implementation and integration.

## Purpose

This directory contains tested patterns for command implementation including agent invocation, checkpoint management, and system integration. Use these guides when implementing common command features or integrating with the agential system.

## Guide Index

### command-patterns-overview.md
**Topic**: Overview of command patterns and selection guide
**Audience**: All developers implementing commands
**Prerequisites**: Command development fundamentals

### command-patterns-agents.md
**Topic**: Patterns for invoking and coordinating agents
**Audience**: Developers integrating agents into commands
**Prerequisites**: Command fundamentals, agent architecture

### command-patterns-checkpoints.md
**Topic**: Checkpoint and resume functionality patterns
**Audience**: Developers implementing long-running workflows
**Prerequisites**: Command fundamentals, state management

### command-patterns-integration.md
**Topic**: System integration patterns (git, validation, testing)
**Audience**: Developers integrating with project infrastructure
**Prerequisites**: Command fundamentals

## Reading Order

Suggested sequence for learning command patterns:
1. command-patterns-overview.md
2. command-patterns-agents.md (if using agents)
3. command-patterns-checkpoints.md (if long-running)
4. command-patterns-integration.md

## Navigation

- [← Parent Directory](../../README.md)
- [Related: execution-enforcement/](../execution-enforcement/README.md)

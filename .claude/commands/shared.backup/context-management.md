# Context Management

## Overview
Efficient context management for hierarchical agent workflows.

## Context Reduction Strategies

### Metadata-Only Passing
Extract essential metadata only (99% reduction: 5000 → 50 tokens).

### Forward Message Pattern
Pass subagent responses directly without re-summarization (95% reduction).

### Progressive Pruning
Remove completed phase data after checkpoints (70% reduction).

## Target Metrics
- Workflow Context: <30% of max tokens
- Peak Usage: <60% during parallel operations
- Cleanup Frequency: After each completed phase

# Adaptive Planning

## Overview
Automatic plan revision during implementation based on complexity and test failures.

## Triggers

### Complexity Detection
Phase complexity score >8 or >10 tasks triggers automatic expansion.

### Test Failure Patterns
2+ consecutive failures suggest missing prerequisites.

### Scope Drift
Manual flag `--report-scope-drift` for discovered out-of-scope work.

## Behavior
- Auto-invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases)
- Maximum 2 replans per phase prevents infinite loops

## See Also
- [Revise Auto-Mode](revise-auto-mode.md)
- [Phase Execution](phase-execution.md)

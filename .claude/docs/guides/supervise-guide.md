# /supervise Command Usage Guide

## Overview

The `/supervise` command provides clean multi-agent workflow orchestration through a standardized 7-phase process. It automatically detects workflow scope, delegates to specialized agents, and manages artifact creation with enhanced error handling and checkpoint recovery.

## Workflow Scope Types

The command automatically detects the workflow type from your description and executes only the appropriate phases:

### 1. Research-Only Workflow

**Keywords**: "research [topic]" without "plan" or "implement"

**Use Case**: Pure exploratory research

**Phases Executed**: 0-1 only

**Artifacts Created**: 2-4 research reports

**No plan created, no summary**

Example:
```bash
/supervise "research API authentication patterns"

# Expected behavior:
# - Scope detected: research-only
# - Phases executed: 0, 1
# - Artifacts: 2-3 research reports
# - No plan, no implementation, no summary
```

### 2. Research-and-Plan Workflow (MOST COMMON)

**Keywords**: "research...to create plan", "analyze...for planning"

**Use Case**: Research to inform planning

**Phases Executed**: 0-2 only

**Artifacts Created**: Research reports + implementation plan

**No summary** (no implementation occurred)

Example:
```bash
/supervise "research the authentication module to create a refactor plan"

# Expected behavior:
# - Scope detected: research-and-plan
# - Phases executed: 0, 1, 2
# - Artifacts: 4 research reports + 1 implementation plan
# - No implementation, no summary (per standards)
# - Plan ready for execution with /implement
```

### 3. Full-Implementation Workflow

**Keywords**: "implement", "build", "add feature"

**Use Case**: Complete feature development

**Phases Executed**: 0-4, 6

**Phase 5 Conditional**: Only runs on test failures

**Artifacts Created**: Reports + plan + implementation + summary

Example:
```bash
/supervise "implement OAuth2 authentication for the API"

# Expected behavior:
# - Scope detected: full-implementation
# - Phases executed: 0, 1, 2, 3, 4, 6
# - Phase 5 conditional on test failures
# - Artifacts: reports + plan + implementation + summary
```

### 4. Debug-Only Workflow

**Keywords**: "fix [bug]", "debug [issue]", "troubleshoot [error]"

**Use Case**: Bug fixing without new implementation

**Phases Executed**: 0, 1, 5 only

**Artifacts Created**: Research reports + debug report

**No new plan or summary**

Example:
```bash
/supervise "fix the token refresh bug in auth.js"

# Expected behavior:
# - Scope detected: debug-only
# - Phases executed: 0, 1, 5
# - Artifacts: research reports + debug report
# - No new plan or implementation (fixes existing code)
```

## Common Usage Patterns

### Pattern 1: Workflow Scope Detection

```bash
# Detect workflow scope and configure phases
WORKFLOW_DESCRIPTION="research authentication patterns to create implementation plan"
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4,6"
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE
```

### Pattern 2: Conditional Phase Execution

```bash
# Check if phase should run
should_run_phase 3 || {
  echo "⏭️  Skipping Phase 3 (Implementation)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  exit 0
}

echo "Executing Phase 3: Implementation"
```

### Pattern 3: Error Handling with Recovery

```bash
# Classify error and determine recovery
ERROR_MSG="Connection timeout after 30 seconds"
ERROR_TYPE=$(classify_error "$ERROR_MSG")

if [ "$ERROR_TYPE" == "transient" ]; then
  echo "Transient error detected, retrying..."
  retry_with_backoff 3 1000 curl "https://api.example.com"
else
  echo "Permanent error:"
  suggest_recovery "$ERROR_TYPE" "$ERROR_MSG"
  exit 1
fi
```

### Pattern 4: Progress Markers

```bash
# Emit progress markers at phase transitions
emit_progress "1" "Invoking 4 research agents in parallel"
# ... agent invocations ...
emit_progress "1" "All research agents completed"
emit_progress "2" "Planning phase started"
```

## Performance Targets

Expected performance characteristics:

- **Context Usage**: <25% throughout workflow
- **File Creation Rate**: 100% with auto-recovery (single retry for transient failures)
- **Recovery Rate**: >95% for transient errors (timeouts, file locks)
- **Performance Overhead**: <5% for recovery infrastructure
- **Enhanced Error Reporting**:
  - Error location extraction accuracy: >90%
  - Error type categorization accuracy: >85%
  - Error reporting overhead: <30ms per error (negligible)

## Auto-Recovery Features

The command implements verification-fallback pattern with single-retry for transient errors.

**Key Behaviors**:
- Transient errors (timeouts, file locks): Single retry after 1s delay
- Permanent errors (syntax, dependencies): Fail-fast with diagnostics
- Partial research failure: Continue if ≥50% agents succeed

**See**: [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md)

## Enhanced Error Reporting

Failed operations receive enhanced diagnostics via error-handling.sh:
- Error location extraction (file:line parsing)
- Error type categorization (timeout, syntax, dependency, unknown)
- Context-specific recovery suggestions

**See**: [Error Handling Library](../../lib/error-handling.sh)

## Checkpoint Resume

Checkpoints saved after Phases 1-4. Auto-resumes from last completed phase on startup.

**Behavior**: Validates checkpoint → Skips completed phases → Resumes seamlessly

**See**: [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md)

## Available Utility Functions

All utility functions are sourced from library files. This table documents the complete API:

### Workflow Detection Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `detect_workflow_scope()` | workflow-detection.sh | Determine workflow type from description | `SCOPE=$(detect_workflow_scope "$DESC")` |
| `should_run_phase()` | workflow-detection.sh | Check if phase executes for current scope | `should_run_phase 3 \|\| exit 0` |

### Error Handling Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `classify_error()` | error-handling.sh | Classify error type (transient/permanent/fatal) | `TYPE=$(classify_error "$ERROR_MSG")` |
| `suggest_recovery()` | error-handling.sh | Suggest recovery action based on error type | `suggest_recovery "$ERROR_TYPE" "$MSG"` |
| `retry_with_backoff()` | error-handling.sh | Retry operation with exponential backoff | `retry_with_backoff 3 1000 operation` |

### Checkpoint Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `save_checkpoint()` | checkpoint-utils.sh | Save workflow state | `save_checkpoint "$PHASE" "$STATE"` |
| `restore_checkpoint()` | checkpoint-utils.sh | Restore workflow state | `restore_checkpoint` |

### Progress Tracking Functions

| Function | Library | Purpose | Usage Example |
|----------|---------|---------|---------------|
| `emit_progress()` | unified-logger.sh | Emit progress marker | `emit_progress "1" "Research complete"` |

## Troubleshooting

### Common Issues

**Issue**: Workflow scope not detected correctly

**Solution**: Ensure your description includes clear keywords:
- For research-only: "research [topic]"
- For planning: "research...to create plan"
- For implementation: "implement [feature]"
- For debugging: "fix [bug]" or "debug [issue]"

**Issue**: Phase skipped unexpectedly

**Solution**: Check the detected workflow scope. Use `should_run_phase N` to verify phase execution logic.

**Issue**: Checkpoint resume failing

**Solution**: Verify checkpoint file exists and is readable. See [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) for migration details.

## Related Documentation

- [/supervise Phase Reference](../reference/supervise-phases.md) - Detailed phase documentation
- [Command Reference](../reference/command-reference.md) - All available commands
- [Orchestration Troubleshooting](orchestration-troubleshooting.md) - Advanced debugging
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - Auto-recovery pattern
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Resume capability

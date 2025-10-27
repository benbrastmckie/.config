# Common Error Handling Patterns

## Validation Errors
Check inputs before proceeding. Fail fast with clear messages.

## State Errors
Use checkpoints to enable rollback on state corruption.

## External Tool Errors
Graceful degradation when optional tools unavailable.

## Network Errors
Retry with exponential backoff for transient failures.

## See Also
- [Error Recovery](error-recovery.md)

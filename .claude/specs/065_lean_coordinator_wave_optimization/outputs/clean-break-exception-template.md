# Clean-Break Exception: Dual-Mode Support in lean-coordinator

## Exception Type
Backward Compatibility Exception

## Rationale
The lean-coordinator agent requires dual-mode support (file-based and plan-based) to maintain compatibility with the existing /lean-build command while enabling optimized plan-driven execution for /lean-implement.

## Affected Components
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md`
- Execution mode detection logic (STEP 0)
- Input parameter: `execution_mode` (file-based | plan-based)

## Compatibility Requirements

### File-Based Mode (Legacy)
- **Used By**: /lean-build command
- **Behavior**: Single-wave execution, no dependency analysis
- **Purpose**: Backward compatibility for existing workflows

### Plan-Based Mode (Optimized)
- **Used By**: /lean-implement command
- **Behavior**: Multi-wave orchestration with plan metadata parsing
- **Purpose**: 96% context reduction via brief summaries

## Future Consolidation Path
Once /lean-build adopts plan-driven architecture, modes can be consolidated:
1. Update /lean-build to generate inline plans
2. Remove file-based mode from lean-coordinator
3. Simplify coordinator to single execution path
4. Estimated effort: 4-6 hours (low complexity)

## Clean-Break Standard Compliance
This exception is documented per clean-break development standard section:
> "Internal tooling changes: ALWAYS use clean-break (no deprecation periods)"

However, external command interfaces (/lean-build) require gradual migration to prevent user disruption.

## Approval Status
- **Approved By**: Implementation Plan 001-lean-coordinator-wave-optimization-plan.md
- **Review Date**: 2025-12-09
- **Expiration**: When /lean-build migrates to plan-driven mode

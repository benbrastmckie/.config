# Coordinate Command Archive

## Archival Date
2025-11-18

## Reason for Archival
The /coordinate command was archived to simplify the codebase. The functionality has been split into dedicated commands (/build, /plan, /debug, /research, /revise) which provide more focused workflows.

## What Was Archived

### Command
- `coordinate.md` - Main coordinate command file

### Agents (Coordinate-Exclusive Only)
- `workflow-classifier.md` - Classification-only agent for semantic workflow type analysis
- `revision-specialist.md` - Revises existing implementation plans based on research

**Note**: `implementer-coordinator.md` was NOT archived as it is a dependent agent for /build command.

### Libraries (Coordinate-Exclusive Only)
- `context-pruning.sh` - Aggressive context pruning for subagent workflows
- `verification-helpers.sh` - Concise verification patterns for orchestration commands
- `validate-context-reduction.sh` - Validation utility for context reduction

**Note**: `unified-logger.sh` was NOT archived as it is used by 6+ other libraries (metadata-extraction.sh, artifact-creation.sh, artifact-registry.sh, workflow-initialization.sh, workflow-llm-classifier.sh, workflow-scope-detection.sh).

**Note**: `dependency-analyzer.sh` was NOT archived as it is used by the implementer-coordinator agent which is required by /build command.

**Note**: `library-sourcing.sh` was NOT archived as it provides shared library sourcing functionality. It was updated to remove coordinate-specific library references.

### Documentation
- `docs/architecture/coordinate-state-management.md` - State management architecture
- `docs/architecture/coordinate-state-management-overview.md` - State overview
- `docs/architecture/coordinate-state-management-states.md` - State definitions
- `docs/architecture/coordinate-state-management-examples.md` - Usage examples
- `docs/architecture/coordinate-state-management-transitions.md` - State transitions
- `docs/guides/coordinate-command-index.md` - Command index
- `docs/guides/coordinate-architecture.md` - Architecture overview
- `docs/guides/coordinate-usage-guide.md` - Usage patterns
- `docs/guides/coordinate-troubleshooting.md` - Troubleshooting guide

### Tests
- `test_coordinate_basic.sh`
- `test_coordinate_all.sh`
- `test_coordinate_state_variables.sh`
- `test_coordinate_exit_trap_timing.sh`
- `test_coordinate_bash_block_fixes_integration.sh`
- `test_coordinate_verification.sh`
- `verify_coordinate_standard11.sh`
- `test_coordinate_delegation.sh.bak`
- `test_coordinate_standards.sh`
- `test_coordinate_waves.sh`
- `test_verification_helpers.sh`
- `test_library_sourcing_order.sh`

### Scripts
- `analyze-coordinate-performance.sh` - Performance analysis for coordinate

## What Was Preserved (Shared Infrastructure)

### Shared Libraries (Used by Multiple Commands)
- `workflow-state-machine.sh` - Used by build, plan, debug, research, revise
- `state-persistence.sh` - Used by build, plan, debug, research, revise
- `error-handling.sh` - Used by build, plan, debug, research, revise
- `workflow-initialization.sh` - Used by debug, research, plan
- `unified-logger.sh` - Used by metadata-extraction.sh and 5 other libraries

### Shared Agents (Used by Multiple Commands)
- `implementer-coordinator.md` - Used by build command
- `research-specialist.md` - Used by plan, research, debug, revise
- `research-sub-supervisor.md` - Used by plan, research, revise
- `plan-architect.md` - Used by plan, debug, revise

## Files Cleaned Up
- Checkpoint files: `.claude/data/checkpoints/coordinate_*.json` (15+ files)
- Temporary files: `.claude/tmp/workflow_coordinate_*.sh` (50+ files)
- Temporary description files: `.claude/tmp/coordinate_workflow_desc*.txt`

## Restoration Instructions

To restore the coordinate command:

1. Move files from this archive back to their original locations:
   ```bash
   # Command
   mv archive/coordinate/commands/coordinate.md commands/

   # Agents
   mv archive/coordinate/agents/*.md agents/

   # Libraries
   mv archive/coordinate/lib/*.sh lib/

   # Tests
   mv archive/coordinate/tests/*.sh tests/

   # Documentation
   mv archive/coordinate/docs/architecture/*.md docs/architecture/
   mv archive/coordinate/docs/guides/*.md docs/guides/

   # Scripts
   mv archive/coordinate/scripts/*.sh scripts/
   ```

2. Update library-sourcing.sh to include coordinate-specific libraries
3. Update command-reference.md to include /coordinate entry
4. Update agent-reference.md to mark agents as active

## Related Documentation
- Pre-archival backup: `.claude/backups/pre-coordinate-archival-20251118/`
- Research report: `/home/benjamin/.config/.claude/specs/799_coordinate_command_all_its_dependencies_order/reports/001_coordinate_dependencies.md`
- Implementation plan: `/home/benjamin/.config/.claude/specs/799_coordinate_command_all_its_dependencies_order/plans/001_coordinate_command_all_its_dependencies__plan.md`

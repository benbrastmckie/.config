# Coordinate Command Dependency Analysis Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Coordinate command archival dependency analysis
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command has extensive dependencies including 9 library files, 5 agent files, 9 documentation files, and multiple test files. Analysis reveals that 4 libraries (context-pruning.sh, dependency-analyzer.sh, unified-logger.sh, verification-helpers.sh) and 3 agents (workflow-classifier.md, implementer-coordinator.md, revision-specialist.md) are exclusively or primarily used by coordinate and can be safely archived. Several libraries (workflow-state-machine.sh, state-persistence.sh, error-handling.sh, workflow-initialization.sh) are shared with other commands and must NOT be archived.

## Findings

### 1. Core Library Dependencies

The coordinate command sources 9 distinct library files (found at lines 104, 116, 124, 133, 445, 477, 643-665, etc.):

#### A. Shared Libraries (CANNOT Archive - Used by Multiple Commands)

| Library | File | Used By Commands | Reference |
|---------|------|------------------|-----------|
| workflow-state-machine.sh | `.claude/lib/workflow-state-machine.sh` | coordinate, build, plan, debug, research, revise | Line 104, 309, 643, 933, etc. |
| state-persistence.sh | `.claude/lib/state-persistence.sh` | coordinate, build, plan, debug, research, revise | Line 116, 235, 310, 644, etc. |
| error-handling.sh | `.claude/lib/error-handling.sh` | coordinate, build, plan, debug, research, revise | Line 124, 311, 658, etc. |
| workflow-initialization.sh | `.claude/lib/workflow-initialization.sh` | coordinate, debug, research, plan | Line 477, 662, 952, etc. |

#### B. Exclusive Libraries (CAN Archive - Only Used by Coordinate)

| Library | File | Purpose | Reference |
|---------|------|---------|-----------|
| context-pruning.sh | `.claude/lib/context-pruning.sh` | Aggressive context pruning for subagent workflows | Line 664, 954, 1278, etc. |
| dependency-analyzer.sh | `.claude/lib/dependency-analyzer.sh` | Builds dependency graphs and execution waves from plan files | Line 665, 955, 1280, etc. |
| unified-logger.sh | `.claude/lib/unified-logger.sh` | Structured logging for orchestration operations | Line 663, 953, 1277, etc. |
| verification-helpers.sh | `.claude/lib/verification-helpers.sh` | Concise verification patterns for orchestration commands | Line 133, 312, 659, etc. |
| library-sourcing.sh | `.claude/lib/library-sourcing.sh` | Consolidated library sourcing for orchestration | Line 445 |

### 2. Agent Dependencies

The coordinate command invokes 5 specialized agents:

#### A. Exclusive Agents (CAN Archive - Only Used by Coordinate)

| Agent | File | Purpose | Reference |
|-------|------|---------|-----------|
| workflow-classifier.md | `.claude/agents/workflow-classifier.md` | Classification-only agent for semantic workflow type analysis | Line 202, coordinate.md + debug.md only |
| implementer-coordinator.md | `.claude/agents/implementer-coordinator.md` | Orchestrates wave-based parallel phase execution | Line 1804, build.md also uses it but for different purpose |
| revision-specialist.md | `.claude/agents/revision-specialist.md` | Revises existing implementation plans based on research | Line 1399, coordinate.md only |

#### B. Shared Agents (CANNOT Archive - Used by Multiple Commands)

| Agent | File | Used By Commands | Reference |
|-------|------|------------------|-----------|
| research-specialist.md | `.claude/agents/research-specialist.md` | coordinate, plan, research, debug, revise | Lines 829, 854, 879, 904 |
| research-sub-supervisor.md | `.claude/agents/research-sub-supervisor.md` | coordinate, plan, research, revise | Line 755 |
| plan-architect.md | `.claude/agents/plan-architect.md` | coordinate, plan, debug, revise | Line 1430 |

### 3. Documentation Dependencies

#### Coordinate-Specific Documentation (CAN Archive)

| Document | Path | Purpose |
|----------|------|---------|
| coordinate-state-management.md | `.claude/docs/architecture/coordinate-state-management.md` | State management architecture |
| coordinate-command-index.md | `.claude/docs/guides/coordinate-command-index.md` | Command index |
| coordinate-architecture.md | `.claude/docs/guides/coordinate-architecture.md` | Architecture overview |
| coordinate-usage-guide.md | `.claude/docs/guides/coordinate-usage-guide.md` | Usage patterns |
| coordinate-troubleshooting.md | `.claude/docs/guides/coordinate-troubleshooting.md` | Troubleshooting guide |
| coordinate-state-management-overview.md | `.claude/docs/architecture/coordinate-state-management-overview.md` | State overview |
| coordinate-state-management-states.md | `.claude/docs/architecture/coordinate-state-management-states.md` | State definitions |
| coordinate-state-management-examples.md | `.claude/docs/architecture/coordinate-state-management-examples.md` | Usage examples |
| coordinate-state-management-transitions.md | `.claude/docs/architecture/coordinate-state-management-transitions.md` | State transitions |

### 4. Test Dependencies

#### Coordinate-Specific Tests (CAN Archive)

| Test File | Path | Purpose |
|-----------|------|---------|
| test_coordinate_basic.sh | `.claude/tests/test_coordinate_basic.sh` | Basic functionality tests |
| test_coordinate_all.sh | `.claude/tests/test_coordinate_all.sh` | Comprehensive test suite |
| test_coordinate_state_variables.sh | `.claude/tests/test_coordinate_state_variables.sh` | State variable tests |
| test_coordinate_exit_trap_timing.sh | `.claude/tests/test_coordinate_exit_trap_timing.sh` | Exit trap timing |
| test_coordinate_bash_block_fixes_integration.sh | `.claude/tests/test_coordinate_bash_block_fixes_integration.sh` | Integration tests |
| test_coordinate_verification.sh | `.claude/tests/test_coordinate_verification.sh` | Verification tests |
| verify_coordinate_standard11.sh | `.claude/tests/verify_coordinate_standard11.sh` | Standard 11 compliance |
| test_coordinate_delegation.sh.bak | `.claude/tests/test_coordinate_delegation.sh.bak` | Backup test file |
| test_coordinate_standards.sh | `.claude/tests/test_coordinate_standards.sh` | Standards compliance |
| test_coordinate_waves.sh | `.claude/tests/test_coordinate_waves.sh` | Wave execution tests |

#### Shared Tests That Reference Coordinate (REVIEW Before Archiving)

| Test File | Path | Notes |
|-----------|------|-------|
| test_verification_helpers.sh | `.claude/tests/test_verification_helpers.sh` | Tests verification-helpers.sh |
| test_library_sourcing_order.sh | `.claude/tests/test_library_sourcing_order.sh` | Tests library-sourcing.sh |

### 5. Scripts Dependencies

| Script | Path | Purpose | Archive? |
|--------|------|---------|----------|
| analyze-coordinate-performance.sh | `.claude/scripts/analyze-coordinate-performance.sh` | Performance analysis for coordinate | YES |

### 6. Data/Checkpoint Files (Cleanup Candidates)

The following checkpoint files in `.claude/data/checkpoints/` can be removed:
- `coordinate_phase_*_*.json` (multiple files from 2025-11-05 to 2025-11-08)
- Total: 15+ checkpoint files

### 7. Temporary Files (Cleanup Candidates)

The following temporary files in `.claude/tmp/` can be removed:
- `workflow_coordinate_*.sh` (50+ temporary workflow files)
- `coordinate_workflow_desc*.txt` (temporary description files)

### 8. Internal Library Dependencies

Some libraries have internal dependencies that must be preserved:

- **library-sourcing.sh** sources: workflow-detection.sh, error-handling.sh, checkpoint-utils.sh, unified-logger.sh, unified-location-detection.sh, metadata-extraction.sh, context-pruning.sh, dependency-analyzer.sh
- **unified-logger.sh** sources: base-utils.sh, timestamp-utils.sh
- **context-pruning.sh** sources itself and uses jq for JSON processing

### 9. Other Files Referencing Coordinate Libraries

These files reference coordinate-specific libraries and need updating/review:

| Library | Dependent Files |
|---------|-----------------|
| context-pruning.sh | library-sourcing.sh, source-libraries-snippet.sh, validate-context-reduction.sh |
| dependency-analyzer.sh | library-sourcing.sh, source-libraries-snippet.sh |
| unified-logger.sh | workflow-initialization.sh, workflow-llm-classifier.sh, workflow-scope-detection.sh, metadata-extraction.sh, artifact-creation.sh, artifact-registry.sh |
| verification-helpers.sh | (self-contained) |

## Recommendations

### 1. Phase 1: Pre-Archival Updates

**CRITICAL**: Before archiving, update these files to remove coordinate references:

1. **Update `.claude/lib/library-sourcing.sh`** (lines 47-55): Remove context-pruning.sh, dependency-analyzer.sh from default library list
2. **Update `.claude/lib/source-libraries-snippet.sh`**: Remove coordinate-specific library references
3. **Update `.claude/docs/reference/command-reference.md`**: Remove /coordinate command entry
4. **Update `.claude/docs/reference/agent-reference.md`**: Mark agents as archived
5. **Update `.claude/agents/README.md`**: Remove coordinate-exclusive agents

### 2. Phase 2: Create Archive Structure

Create archive directory structure:
```
.claude/archive/
├── coordinate/
│   ├── commands/
│   │   └── coordinate.md
│   ├── agents/
│   │   ├── workflow-classifier.md
│   │   ├── implementer-coordinator.md
│   │   └── revision-specialist.md
│   ├── lib/
│   │   ├── context-pruning.sh
│   │   ├── dependency-analyzer.sh
│   │   ├── unified-logger.sh
│   │   ├── verification-helpers.sh
│   │   └── library-sourcing.sh
│   ├── docs/
│   │   ├── architecture/
│   │   │   └── coordinate-state-management*.md
│   │   └── guides/
│   │       └── coordinate-*.md
│   ├── tests/
│   │   └── test_coordinate_*.sh
│   └── scripts/
│       └── analyze-coordinate-performance.sh
```

### 3. Phase 3: Execute Archival

Move files in this order to avoid breaking dependencies:

1. **Tests first** (no dependencies)
2. **Documentation** (no dependencies)
3. **Scripts** (no dependencies)
4. **Agents** (may have references to remove)
5. **Libraries** (update dependents first)
6. **Command file** (last - main entry point)

### 4. Phase 4: Cleanup

1. Remove checkpoint files: `.claude/data/checkpoints/coordinate_*.json`
2. Remove temporary files: `.claude/tmp/workflow_coordinate_*.sh`
3. Update `.gitignore` if needed

### 5. Phase 5: Validation

1. Run remaining test suites to ensure no breakage
2. Verify other commands (build, plan, debug, research, revise) still work
3. Check for broken documentation links

### 6. Risk Mitigation

**HIGH RISK Items**:
- **unified-logger.sh**: Used by 8 other libraries. If archived, must update: workflow-initialization.sh, workflow-llm-classifier.sh, workflow-scope-detection.sh, metadata-extraction.sh, artifact-creation.sh, artifact-registry.sh
- **verification-helpers.sh**: Only used by coordinate but may have tests that reference it

**MEDIUM RISK Items**:
- **library-sourcing.sh**: Primary orchestration library sourcing - removing it affects how libraries are loaded

**Recommendation**: Consider extracting commonly-used functions from unified-logger.sh (like rotate_log_file) to a shared utility before archiving, or mark it as "deprecated but retained" instead of full archival.

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/coordinate.md` (2459+ lines)
- `/home/benjamin/.config/.claude/commands/build.md`
- `/home/benjamin/.config/.claude/commands/plan.md`
- `/home/benjamin/.config/.claude/commands/debug.md`
- `/home/benjamin/.config/.claude/commands/research.md`
- `/home/benjamin/.config/.claude/commands/revise.md`

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` (lines 1-99)
- `/home/benjamin/.config/.claude/lib/dependency-analyzer.sh` (lines 1-99)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (lines 1-99)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (lines 1-99)
- `/home/benjamin/.config/.claude/lib/library-sourcing.sh` (lines 1-99)

### Agent Files Analyzed
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md` (lines 1-99)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 1-99)
- `/home/benjamin/.config/.claude/agents/revision-specialist.md` (lines 1-49)

### Test Files Identified
- `/home/benjamin/.config/.claude/tests/test_coordinate_*.sh` (10 files)
- `/home/benjamin/.config/.claude/tests/test_verification_helpers.sh`
- `/home/benjamin/.config/.claude/tests/test_library_sourcing_order.sh`

### Documentation Files Identified
- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management*.md` (5 files)
- `/home/benjamin/.config/.claude/docs/guides/coordinate-*.md` (4 files)

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_coordinate_command_all_its_dependencies__plan.md](../plans/001_coordinate_command_all_its_dependencies__plan.md)
- **Implementation**: [Will be updated during implementation]
- **Date**: 2025-11-18

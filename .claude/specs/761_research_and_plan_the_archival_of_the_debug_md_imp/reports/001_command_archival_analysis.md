# Command Archival Infrastructure Analysis Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Archival analysis of debug.md, implement.md, plan.md, research.md, and revise.md commands
- **Report Type**: codebase analysis

## Executive Summary

This report analyzes the infrastructure dependencies for 5 target commands (debug.md, implement.md, plan.md, research.md, revise.md) to determine which components can be safely archived. The analysis reveals that most infrastructure is SHARED with other active commands (build.md, fix.md, coordinate.md, research-plan.md, research-revise.md, research-report.md), meaning very few components are exclusively used by the target commands. Only 2 agents, 2 libraries, 5 documentation files, and 4 test files can be safely archived. The majority of infrastructure must be preserved to support the remaining commands.

## Findings

### Command Files Analysis

The 5 target commands to archive are located in `/home/benjamin/.config/.claude/commands/`:

| Command | File Path | Lines | Description |
|---------|-----------|-------|-------------|
| debug.md | /home/benjamin/.config/.claude/commands/debug.md | 402 | Investigate issues and create diagnostic report |
| implement.md | /home/benjamin/.config/.claude/commands/implement.md | 305 | Execute implementation plan with testing |
| plan.md | /home/benjamin/.config/.claude/commands/plan.md | 970 | Create detailed implementation plan |
| research.md | /home/benjamin/.config/.claude/commands/research.md | 1011 | Research topic using hierarchical multi-agent |
| revise.md | /home/benjamin/.config/.claude/commands/revise.md | 796 | Revise implementation plans or reports |

**Related Commands That Will Remain Active**:
- build.md - Uses similar infrastructure (implementer-coordinator, debug-analyst)
- fix.md - Uses plan-architect, research-specialist, debug-analyst
- coordinate.md - Uses most agents (workflow-classifier, research-specialist, plan-architect, etc.)
- research-plan.md - Uses research-specialist, plan-architect
- research-revise.md - Uses research-specialist, plan-architect
- research-report.md - Uses research-specialist

### Agent Dependencies

Analysis of agents referenced by the 5 target commands:

| Agent | Used By Target Commands | Also Used By Other Commands | Classification |
|-------|------------------------|----------------------------|----------------|
| debug-analyst.md | debug.md | fix.md, build.md, coordinate.md | SHARED |
| debug-specialist.md | (indirect) | build.md, coordinate.md | SHARED |
| code-writer.md | implement.md | (none) | **EXCLUSIVE** |
| plan-architect.md | plan.md | fix.md, coordinate.md, research-plan.md, research-revise.md | SHARED |
| plan-complexity-classifier.md | plan.md | coordinate.md | SHARED |
| research-specialist.md | research.md, plan.md | fix.md, coordinate.md, research-plan.md, research-revise.md, research-report.md | SHARED |
| research-synthesizer.md | research.md | coordinate.md | SHARED |
| spec-updater.md | research.md | coordinate.md | SHARED |
| revision-specialist.md | (related to revise.md) | coordinate.md | SHARED |
| implementation-researcher.md | (indirect) | coordinate.md | SHARED |

**EXCLUSIVE Agents (Safe to Archive)**:
1. `/home/benjamin/.config/.claude/agents/code-writer.md` - Only used by implement.md
2. `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Only used by implement workflow

### Library Dependencies

Analysis of libraries sourced by the 5 target commands:

| Library | Used By Target Commands | Also Used By Other Commands | Classification |
|---------|------------------------|----------------------------|----------------|
| debug-utils.sh | debug.md | fix.md, build.md | SHARED |
| error-handling.sh | debug.md, implement.md, plan.md | fix.md, build.md, coordinate.md, research-*.md | SHARED |
| checkpoint-utils.sh | implement.md | build.md, coordinate.md | SHARED |
| complexity-utils.sh | implement.md, plan.md | coordinate.md | SHARED |
| adaptive-planning-logger.sh | implement.md | (none - may exist but unused) | **EXCLUSIVE** |
| state-persistence.sh | plan.md | fix.md, build.md, coordinate.md, research-*.md | SHARED |
| workflow-state-machine.sh | plan.md | fix.md, build.md, coordinate.md, research-*.md | SHARED |
| verification-helpers.sh | debug.md, plan.md | fix.md, coordinate.md | SHARED |
| unified-location-detection.sh | debug.md, plan.md, research.md | fix.md, coordinate.md, research-*.md, optimize-claude.md | SHARED |
| metadata-extraction.sh | plan.md, research.md | coordinate.md | SHARED |
| topic-decomposition.sh | research.md | coordinate.md | SHARED |
| artifact-creation.sh | research.md | coordinate.md | SHARED |
| template-integration.sh | research.md | coordinate.md | SHARED |
| overview-synthesis.sh | research.md | coordinate.md | SHARED |
| topic-utils.sh | research.md | coordinate.md | SHARED |
| detect-project-dir.sh | research.md | multiple commands | SHARED |
| validate-plan.sh | plan.md | (none) | **EXCLUSIVE** |

**EXCLUSIVE Libraries (Safe to Archive)**:
1. `/home/benjamin/.config/.claude/lib/adaptive-planning-logger.sh` - Only used by implement.md
2. `/home/benjamin/.config/.claude/lib/validate-plan.sh` - Only used by plan.md

### Template Dependencies

No templates were found that are exclusively used by the 5 target commands. The template system in `.claude/commands/templates/` is shared infrastructure.

### Documentation Dependencies

Documentation files related to the 5 target commands:

| Documentation | Related Command | Also Documents Other Commands | Classification |
|--------------|-----------------|------------------------------|----------------|
| debug-command-guide.md | debug.md | References fix.md | **EXCLUSIVE** |
| implement-command-guide.md | implement.md | (none) | **EXCLUSIVE** |
| plan-command-guide.md | plan.md | (none) | **EXCLUSIVE** |
| research-command-guide.md | research.md | (none) | **EXCLUSIVE** |
| revise-command-guide.md | revise.md | (none) | **EXCLUSIVE** |
| implementation-guide.md | implement.md | General implementation patterns | SHARED |
| research-plan-command-guide.md | (none) | research-plan.md | KEEP |
| research-revise-command-guide.md | (none) | research-revise.md | KEEP |
| research-report-command-guide.md | (none) | research-report.md | KEEP |
| revision-specialist-agent-guide.md | related | coordinate.md | SHARED |
| revision-guide.md | revise.md | General patterns | SHARED |

**EXCLUSIVE Documentation (Safe to Archive)**:
1. `/home/benjamin/.config/.claude/docs/guides/debug-command-guide.md`
2. `/home/benjamin/.config/.claude/docs/guides/implement-command-guide.md`
3. `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`
4. `/home/benjamin/.config/.claude/docs/guides/research-command-guide.md`
5. `/home/benjamin/.config/.claude/docs/guides/revise-command-guide.md`

### Test Dependencies

Test files for the 5 target commands:

| Test File | Tests Command | Also Tests Other Commands | Classification |
|-----------|---------------|--------------------------|----------------|
| test_auto_debug_integration.sh | debug.md | (none) | **EXCLUSIVE** |
| test_plan_command.sh | plan.md | (none) | **EXCLUSIVE** |
| test_adaptive_planning.sh | plan.md, implement.md | (none) | **EXCLUSIVE** |
| e2e_implement_plan_execution.sh | implement.md | (none) | **EXCLUSIVE** |
| test_revise_automode.sh | revise.md | (none) | **EXCLUSIVE** |
| test_revision_specialist.sh | revise.md | revision-specialist agent | SHARED |
| test_subprocess_isolation_research_plan.sh | research.md | research-plan.md | SHARED |
| test_coordinate_research_complexity_fix.sh | (none) | coordinate.md | KEEP |

**EXCLUSIVE Tests (Safe to Archive)**:
1. `/home/benjamin/.config/.claude/tests/test_auto_debug_integration.sh`
2. `/home/benjamin/.config/.claude/tests/test_plan_command.sh`
3. `/home/benjamin/.config/.claude/tests/test_adaptive_planning.sh`
4. `/home/benjamin/.config/.claude/tests/e2e_implement_plan_execution.sh`

Note: test_revise_automode.sh tests revise.md but revise.md is used by coordinate.md via revision-specialist.

## Dependency Classification

### EXCLUSIVE Components (Safe to Archive)

These components are ONLY used by the 5 target commands and can be safely archived:

**Command Files (5)**:
- `/home/benjamin/.config/.claude/commands/debug.md`
- `/home/benjamin/.config/.claude/commands/implement.md`
- `/home/benjamin/.config/.claude/commands/plan.md`
- `/home/benjamin/.config/.claude/commands/research.md`
- `/home/benjamin/.config/.claude/commands/revise.md`

**Agent Files (2)**:
- `/home/benjamin/.config/.claude/agents/code-writer.md`
- `/home/benjamin/.config/.claude/agents/implementation-executor.md`

**Library Files (2)**:
- `/home/benjamin/.config/.claude/lib/adaptive-planning-logger.sh`
- `/home/benjamin/.config/.claude/lib/validate-plan.sh`

**Documentation Files (5)**:
- `/home/benjamin/.config/.claude/docs/guides/debug-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/implement-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/research-command-guide.md`
- `/home/benjamin/.config/.claude/docs/guides/revise-command-guide.md`

**Test Files (4)**:
- `/home/benjamin/.config/.claude/tests/test_auto_debug_integration.sh`
- `/home/benjamin/.config/.claude/tests/test_plan_command.sh`
- `/home/benjamin/.config/.claude/tests/test_adaptive_planning.sh`
- `/home/benjamin/.config/.claude/tests/e2e_implement_plan_execution.sh`

**Total EXCLUSIVE: 18 files**

### SHARED Components (Must NOT Archive)

These components are used by other commands and MUST be preserved:

**Agent Files (10+)**:
- debug-analyst.md (used by fix.md, build.md, coordinate.md)
- debug-specialist.md (used by build.md, coordinate.md)
- plan-architect.md (used by fix.md, coordinate.md, research-plan.md, research-revise.md)
- plan-complexity-classifier.md (used by coordinate.md)
- research-specialist.md (used by fix.md, coordinate.md, research-*.md)
- research-synthesizer.md (used by coordinate.md)
- spec-updater.md (used by coordinate.md)
- revision-specialist.md (used by coordinate.md)
- implementation-researcher.md (used by coordinate.md)
- implementer-coordinator.md (used by build.md, coordinate.md)

**Library Files (15+)**:
- debug-utils.sh (used by fix.md, build.md)
- error-handling.sh (used by fix.md, build.md, coordinate.md, research-*.md)
- checkpoint-utils.sh (used by build.md, coordinate.md)
- complexity-utils.sh (used by coordinate.md)
- state-persistence.sh (used by fix.md, build.md, coordinate.md, research-*.md)
- workflow-state-machine.sh (used by fix.md, build.md, coordinate.md, research-*.md)
- verification-helpers.sh (used by fix.md, coordinate.md)
- unified-location-detection.sh (used by fix.md, coordinate.md, research-*.md, optimize-claude.md)
- metadata-extraction.sh (used by coordinate.md)
- topic-decomposition.sh (used by coordinate.md)
- artifact-creation.sh (used by coordinate.md)
- template-integration.sh (used by coordinate.md)
- overview-synthesis.sh (used by coordinate.md)
- topic-utils.sh (used by coordinate.md)
- detect-project-dir.sh (used by multiple commands)

**Documentation Files**:
- revision-guide.md (general patterns)
- revision-specialist-agent-guide.md (used by coordinate.md)
- implementation-guide.md (general patterns)

**Test Files**:
- test_revision_specialist.sh (tests agent used by coordinate.md)
- test_subprocess_isolation_research_plan.sh (tests research-plan.md)

## Recommendations

### 1. Create Archive Directory Structure
Create an archive directory to preserve the commands without breaking the codebase:
```bash
mkdir -p /home/benjamin/.config/.claude/archive/legacy-workflow-commands/{commands,agents,lib,docs,tests}
```

### 2. Move EXCLUSIVE Components in Phases
**Phase 1 - Command Files**:
```bash
mv .claude/commands/debug.md .claude/archive/legacy-workflow-commands/commands/
mv .claude/commands/implement.md .claude/archive/legacy-workflow-commands/commands/
mv .claude/commands/plan.md .claude/archive/legacy-workflow-commands/commands/
mv .claude/commands/research.md .claude/archive/legacy-workflow-commands/commands/
mv .claude/commands/revise.md .claude/archive/legacy-workflow-commands/commands/
```

**Phase 2 - Agent Files**:
```bash
mv .claude/agents/code-writer.md .claude/archive/legacy-workflow-commands/agents/
mv .claude/agents/implementation-executor.md .claude/archive/legacy-workflow-commands/agents/
```

**Phase 3 - Library Files**:
```bash
mv .claude/lib/adaptive-planning-logger.sh .claude/archive/legacy-workflow-commands/lib/
mv .claude/lib/validate-plan.sh .claude/archive/legacy-workflow-commands/lib/
```

**Phase 4 - Documentation Files**:
```bash
mv .claude/docs/guides/debug-command-guide.md .claude/archive/legacy-workflow-commands/docs/
mv .claude/docs/guides/implement-command-guide.md .claude/archive/legacy-workflow-commands/docs/
mv .claude/docs/guides/plan-command-guide.md .claude/archive/legacy-workflow-commands/docs/
mv .claude/docs/guides/research-command-guide.md .claude/archive/legacy-workflow-commands/docs/
mv .claude/docs/guides/revise-command-guide.md .claude/archive/legacy-workflow-commands/docs/
```

**Phase 5 - Test Files**:
```bash
mv .claude/tests/test_auto_debug_integration.sh .claude/archive/legacy-workflow-commands/tests/
mv .claude/tests/test_plan_command.sh .claude/archive/legacy-workflow-commands/tests/
mv .claude/tests/test_adaptive_planning.sh .claude/archive/legacy-workflow-commands/tests/
mv .claude/tests/e2e_implement_plan_execution.sh .claude/archive/legacy-workflow-commands/tests/
```

### 3. Update Cross-References
After archiving, update any documentation that references the archived commands:
- Update `.claude/docs/reference/command-reference.md` to note archived status
- Update `.claude/agents/README.md` to note archived agents
- Update CLAUDE.md if it references these commands

### 4. Preserve Backward Compatibility
Create stub files in original locations that redirect to archive:
```markdown
# /debug - ARCHIVED

This command has been archived to `.claude/archive/legacy-workflow-commands/commands/debug.md`.

Use `/coordinate` or `/fix` for debugging workflows instead.
```

### 5. Run Test Suite After Archival
Execute the full test suite to ensure no regressions:
```bash
.claude/tests/run_all_tests.sh
```

### 6. Consider Keeping revise.md Active
The revise.md command is used indirectly by coordinate.md through revision-specialist.md. Consider keeping it active or ensuring coordinate.md can function without it.

## References

### Files Analyzed

**Command Files**:
- `/home/benjamin/.config/.claude/commands/debug.md:1-402`
- `/home/benjamin/.config/.claude/commands/implement.md:1-305`
- `/home/benjamin/.config/.claude/commands/plan.md:1-970`
- `/home/benjamin/.config/.claude/commands/research.md:1-1011`
- `/home/benjamin/.config/.claude/commands/revise.md:1-796`

**Agent Files** (all in /home/benjamin/.config/.claude/agents/):
- debug-analyst.md, debug-specialist.md, code-writer.md
- plan-architect.md, plan-complexity-classifier.md
- research-specialist.md, research-synthesizer.md
- spec-updater.md, revision-specialist.md
- implementation-executor.md, implementer-coordinator.md

**Library Files** (all in /home/benjamin/.config/.claude/lib/):
- debug-utils.sh, error-handling.sh, checkpoint-utils.sh
- complexity-utils.sh, adaptive-planning-logger.sh
- state-persistence.sh, workflow-state-machine.sh
- verification-helpers.sh, unified-location-detection.sh
- metadata-extraction.sh, topic-decomposition.sh
- artifact-creation.sh, template-integration.sh
- overview-synthesis.sh, topic-utils.sh, validate-plan.sh

**Other Commands That Share Infrastructure**:
- `/home/benjamin/.config/.claude/commands/build.md`
- `/home/benjamin/.config/.claude/commands/fix.md`
- `/home/benjamin/.config/.claude/commands/coordinate.md`
- `/home/benjamin/.config/.claude/commands/research-plan.md`
- `/home/benjamin/.config/.claude/commands/research-revise.md`
- `/home/benjamin/.config/.claude/commands/research-report.md`

**Test Files** (all in /home/benjamin/.config/.claude/tests/):
- test_auto_debug_integration.sh
- test_plan_command.sh
- test_adaptive_planning.sh
- e2e_implement_plan_execution.sh
- test_revise_automode.sh

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_research_and_plan_the_archival_of_the_de_plan.md](../plans/001_research_and_plan_the_archival_of_the_de_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17

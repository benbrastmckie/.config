# Development Workflow

This workflow guide describes the standard development process for the `.claude/` system.

## Overview

Standard workflow: **research → plan → implement → test → commit → summarize**

The spec updater agent manages artifacts in topic-based directories and maintains cross-references. Adaptive planning adjusts plans during implementation when needed.

## Workflow Phases

### Phase 1: Research
Create research reports for complex topics.

```bash
/research "authentication system design"
```

**Output**: `specs/{NNN_topic}/reports/001_report_name.md`

### Phase 2: Planning
Generate implementation plans based on research.

```bash
/plan "implement OAuth authentication" specs/reports/001_auth_research.md
```

**Output**: `specs/{NNN_topic}/plans/001_implementation_plan.md`

### Phase 3: Implementation
Execute plans phase-by-phase with testing and commits.

```bash
/implement specs/plans/001_oauth_implementation.md
```

**Process**:
- Implements each phase sequentially
- Runs tests after each phase
- Creates git commits for completed phases
- Adaptive planning adjusts plan when needed

### Phase 4: Summarization
Generate implementation summaries linking plans to code.

```bash
# Automatically created by /implement when complete
```

**Output**: `specs/{NNN_topic}/summaries/001_implementation_summary.md`

### Phase 5: Debugging (When Needed)
Create debug reports for issues encountered.

```bash
/debug "test failures in authentication flow"
```

**Output**: `specs/{NNN_topic}/debug/001_debug_report.md` (COMMITTED to git)

## Topic-Based Structure

All artifacts organized by topic: `specs/{NNN_topic}/`

```
specs/
└── 042_authentication/
    ├── reports/        # Research reports (gitignored)
    ├── plans/          # Implementation plans (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED)
    ├── scripts/        # Investigation scripts (gitignored)
    ├── outputs/        # Test outputs (gitignored)
    ├── artifacts/      # Operation artifacts (gitignored)
    └── backups/        # Backups (gitignored)
```

## Spec Updater Integration

The spec updater agent (`.claude/agents/spec-updater.md`) automatically:
- Creates artifacts in appropriate topic subdirectories
- Maintains cross-references between artifacts
- Manages artifact lifecycle and gitignore compliance
- Ensures topic-based organization consistency

### Spec Updater Checklist
When working with plans:
- [ ] Ensure plan is in topic-based directory structure
- [ ] Create standard subdirectories if needed
- [ ] Update cross-references if artifacts moved
- [ ] Create implementation summary when complete
- [ ] Verify gitignore compliance (debug/ committed, others ignored)

## Artifact Lifecycle

### Core Planning Artifacts (reports/, plans/, summaries/)
- **Lifecycle**: Created during planning/research, preserved
- **Gitignore**: YES (local working artifacts)
- **Cleanup**: Never (preserved for reference)

### Debug Reports (debug/)
- **Lifecycle**: Created during debugging, preserved permanently
- **Gitignore**: NO (COMMITTED for issue tracking)
- **Cleanup**: Never (part of project history)

### Temporary Artifacts (scripts/, outputs/)
- **Lifecycle**: Created during execution, cleaned after workflow
- **Gitignore**: YES
- **Cleanup**: After workflow completion

### Backups and Artifacts
- **Lifecycle**: Created during operations, cleaned periodically
- **Gitignore**: YES
- **Cleanup**: After verification or on demand

## Adaptive Planning

During implementation, plans may be automatically revised when:
1. **Complexity Detection**: Phase complexity score >8 or >10 tasks
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase
3. **Scope Drift**: Manual flag `--report-scope-drift "description"`

See [Adaptive Planning Guide](./adaptive-planning-guide.md) for details.

## Parallel Execution

Plans support phase dependencies for wave-based parallel execution:

```markdown
### Phase 2: Database Schema
dependencies: [1]

### Phase 3: API Endpoints
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]
```

Phases 2 and 3 can run in parallel after Phase 1 completes.

See [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) for details.

## Git Workflow

### Commits
- Create atomic commits after each completed phase
- Include phase number and name in commit message
- Add co-authorship attribution to Claude

### Branches
- Use feature branches for new development
- Create PRs for review before merging

### Example Commit
```
feat(auth): implement Phase 2 - Database schema

Created user authentication tables and indexes
All tests passing

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Related Documentation

- [Development Workflow Concept](../concepts/development-workflow.md) - Detailed workflow documentation
- [Directory Protocols](../concepts/directory-protocols.md) - Topic-based organization
- [Adaptive Planning Guide](./adaptive-planning-guide.md) - Plan revision during implementation
- [Spec Updater Guide](./spec_updater_guide.md) - Artifact management details
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Resumable workflows
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based implementation

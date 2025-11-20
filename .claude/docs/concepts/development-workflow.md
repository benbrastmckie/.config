# Development Workflow

## Planning and Implementation

1. Create research reports in `specs/reports/` for complex topics
2. Generate implementation plans in `specs/plans/` based on research
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in `specs/summaries/` linking plans to code
5. Adaptive planning automatically adjusts plans during implementation

## Spec Updater Integration

[Used by: /plan, /expand, /implement, /orchestrate]

The spec updater agent manages artifacts in topic-based directory structure:

**Agent Role**: `.claude/agents/spec-updater.md`
- Creates artifacts in appropriate topic subdirectories
- Maintains cross-references between artifacts
- Manages artifact lifecycle and gitignore compliance
- Ensures topic-based organization consistency

**Topic-Based Structure**: `specs/{NNN_topic}/`
- `reports/` - Research reports (gitignored)
- `plans/` - Sub-plans (gitignored)
- `summaries/` - Implementation summaries (gitignored)
- `debug/` - Debug reports (COMMITTED for issue tracking)
- `scripts/` - Investigation scripts (gitignored, temporary)
- `outputs/` - Test outputs (gitignored, cleaned after workflow)
- `artifacts/` - Operation artifacts (gitignored)
- `backups/` - Backups (gitignored)

**Spec Updater Checklist** (included in all plan templates):
- Ensure plan is in topic-based directory structure
- Create standard subdirectories if needed
- Update cross-references if artifacts moved
- Create implementation summary when complete
- Verify gitignore compliance (debug/ committed, others ignored)

## Artifact Lifecycle

1. **Core Planning Artifacts** (reports/, plans/, summaries/)
   - Lifecycle: Created during planning/research, preserved
   - Gitignore: YES (local working artifacts)
   - Cleanup: Never (preserved for reference)

2. **Debug Reports** (debug/)
   - Lifecycle: Created during debugging, preserved permanently
   - Gitignore: NO (COMMITTED for issue tracking)
   - Cleanup: Never (part of project history)

3. **Investigation Scripts** (scripts/)
   - Lifecycle: Created during debugging, temporary
   - Gitignore: YES (temporary workflow scripts)
   - Cleanup: Automatic after workflow completion
   - Retention: 0 days (removed immediately after workflow)

4. **Test Outputs** (outputs/)
   - Lifecycle: Created during testing, temporary
   - Gitignore: YES (regenerable test artifacts)
   - Cleanup: Automatic after verification
   - Retention: 0 days (removed after test validation)

5. **Operation Artifacts** (artifacts/)
   - Lifecycle: Created during expansion/collapse, optional cleanup
   - Gitignore: YES (operational metadata)
   - Cleanup: Optional (can be preserved for analysis)
   - Retention: 30 days (configurable)

6. **Backups** (backups/)
   - Lifecycle: Created during migrations/operations
   - Gitignore: YES (large files, regenerable)
   - Cleanup: Optional cleanup after verification
   - Retention: 30 days (configurable)

## Shell Utilities

Located in `.claude/lib/workflow/metadata-extraction.sh`:
- `create_topic_artifact <topic-dir> <type> <name> <content>` - Create artifact
- `cleanup_topic_artifacts <topic-dir> <type> [age-days]` - Clean specific type
- `cleanup_all_temp_artifacts <topic-dir>` - Clean all temporary artifacts

## Usage Pattern

- Plans created by `/plan` include spec updater checklist
- Orchestrator invokes spec updater at phase boundaries
- `/expand` preserves spec updater checklist in expanded files
- Implementation phase uses spec updater for artifact management

## Plan Hierarchy Updates

Located in `.claude/lib/plan/checkbox-utils.sh`:
- Automatically updates checkboxes across plan hierarchy levels after phase completion
- Functions: `update_checkbox()`, `propagate_checkbox_update()`, `mark_phase_complete()`, `verify_checkbox_consistency()`
- Supports Level 0 (single file), Level 1 (expanded phases), Level 2 (stages → phases → main)

**Integration points**:
- `/implement` Step 5: Invokes spec-updater agent after git commit success
- `/orchestrate` Documentation Phase: Updates hierarchy after implementation complete
- Checkpoint field: `hierarchy_updated` tracks update status
- Ensures parent/grandparent plan files stay synchronized with child progress

## Git Workflow

- Feature branches for new development
- Clean, atomic commits with descriptive messages
- Test before committing
- Document breaking changes

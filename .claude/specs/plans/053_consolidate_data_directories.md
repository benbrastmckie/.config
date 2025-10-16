# Consolidate .claude/ Untracked Directories Implementation Plan

/orchestrate when I run /orchestrate, /report, /debug, or any command that involves research, I want those commands to mobilizes subagents to do the research in order to preserve the context window of the primary agent (check that these commands all do this). I also want those research subagents to create a report in the appropriate {relevant_location_in_project}/specs/{NNN_topic}/reports/NNN_*.md (and similarly for debug) which I see is not always taking place currently. Please carefully study .claude/ in order to plan and implement a refactor that overcomes these issues. I don't want those research agents to use the /report command, or any of the other commands. Rather, the research specialists should contain the minimal instructions they need to do the research in question, create the report, and pass a brief summary and reference back to the primary agent. Please carefully research these issues, plan an elegant refactor, implement, the changes, run tests, and update all documentation.

## Metadata
- **Date**: 2025-10-16
- **Feature**: Directory Consolidation
- **Scope**: Move checkpoints/, logs/, registry/ to .claude/data/; keep examples/ as documentation
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (research completed inline)

## Overview

Consolidate untracked runtime directories (checkpoints/, logs/, registry/) into `.claude/data/` to centralize all generated/temporary files in one location. The `.claude/data/` directory already exists with legacy subdirectories, but current code uses `.claude/checkpoints/`, `.claude/logs/`, and `.claude/registry/` with hardcoded paths.

Keep `.claude/examples/` in place as it contains static documentation (tracked in git).

## Success Criteria
- [ ] All library files updated to use `.claude/data/` subdirectories
- [ ] Existing checkpoint/log/registry content migrated successfully
- [ ] Tests pass with new directory structure
- [ ] Documentation updated to reflect new paths
- [ ] `.gitignore` patterns updated if needed
- [ ] No references to old paths in active code

## Technical Design

### Current State
- **checkpoints/**: Active at `.claude/checkpoints/`, hardcoded in checkpoint-utils.sh:28
  - Contains: parallel_ops/, test_*/ subdirectories
  - Used by: 6 shell scripts, referenced in 95 docs
  - Legacy location exists: `.claude/data/checkpoints/` (not used)

- **logs/**: Active at `.claude/logs/`, fallback `${CLAUDE_LOGS_DIR:-.claude/logs}`
  - Contains: adaptive-planning.log, conversion.log, orchestrate.log, approval-decisions.log
  - Used by: unified-logger.sh, adaptive-planning-logger.sh, artifact-operations.sh, error-handling.sh

- **registry/**: Active at `.claude/registry/`, hardcoded as ARTIFACT_REGISTRY_DIR
  - Contains: JSON metadata files, agent-registry.json
  - Used by: artifact-operations.sh, agent-registry-utils.sh

- **examples/**: Contains artifact_creation_workflow.sh (tracked in git)
  - Static documentation demonstrating API usage
  - Should remain in current location

### Target State
```
.claude/
├── data/
│   ├── checkpoints/     # Migrated from .claude/checkpoints/
│   ├── logs/            # Migrated from .claude/logs/
│   ├── registry/        # Migrated from .claude/registry/
│   └── metrics/         # Already exists
├── examples/            # Unchanged (static docs)
└── [other tracked directories]
```

### Path Updates Required
1. **checkpoint-utils.sh**: Update CHECKPOINTS_DIR constant
2. **unified-logger.sh**: Update CLAUDE_LOGS_DIR default
3. **adaptive-planning-logger.sh.backup**: Update log path (if still used)
4. **artifact-operations.sh**: Update ARTIFACT_REGISTRY_DIR constant
5. **agent-registry-utils.sh**: Update REGISTRY_FILE path
6. **error-handling.sh**: Update ERROR_LOG_DIR path

## Implementation Phases

### Phase 1: Update Library Path Constants [COMPLETED]
**Objective**: Update all hardcoded paths in library files to use `.claude/data/` subdirectories
**Complexity**: Medium
**Risk**: Medium (must update all paths correctly to avoid breaking existing functionality)

Tasks:
- [x] Update checkpoint-utils.sh:28 CHECKPOINTS_DIR to `.claude/data/checkpoints`
- [x] Update unified-logger.sh:39 CLAUDE_LOGS_DIR default to `.claude/data/logs`
- [x] Update artifact-operations.sh:72 ARTIFACT_REGISTRY_DIR to `.claude/data/registry`
- [x] Update agent-registry-utils.sh:15 REGISTRY_FILE to `.claude/data/registry/agent-registry.json` (N/A - uses agents/ not registry/)
- [x] Update error-handling.sh:345 ERROR_LOG_DIR to `.claude/data/logs`
- [x] Check adaptive-planning-logger.sh.backup for log path references

Testing:
```bash
# Verify path constants updated correctly
grep -n "CHECKPOINTS_DIR.*\.claude" .claude/lib/checkpoint-utils.sh
grep -n "CLAUDE_LOGS_DIR.*\.claude" .claude/lib/unified-logger.sh
grep -n "ARTIFACT_REGISTRY_DIR.*\.claude" .claude/lib/artifact-operations.sh
grep -n "REGISTRY_FILE.*\.claude" .claude/lib/agent-registry-utils.sh
grep -n "ERROR_LOG_DIR.*\.claude" .claude/lib/error-handling.sh

# Verify all paths use .claude/data/
grep -E "\.claude/(checkpoints|logs|registry)" .claude/lib/*.sh | grep -v "\.claude/data"
```

### Phase 2: Create Target Directory Structure [COMPLETED]
**Objective**: Ensure `.claude/data/` subdirectories exist with proper permissions
**Complexity**: Low
**Risk**: Low

Tasks:
- [x] Create `.claude/data/checkpoints/` if not exists
- [x] Create `.claude/data/logs/` if not exists
- [x] Create `.claude/data/registry/` if not exists
- [x] Verify directory permissions (755)
- [ ] Update `.claude/data/README.md` to document new structure

Testing:
```bash
# Verify directory structure
ls -la .claude/data/
test -d .claude/data/checkpoints && echo "checkpoints OK"
test -d .claude/data/logs && echo "logs OK"
test -d .claude/data/registry && echo "registry OK"
```

### Phase 3: Migrate Existing Content [COMPLETED]
**Objective**: Move existing checkpoint/log/registry files to new locations
**Complexity**: Medium
**Risk**: Medium (must preserve all existing data)

Tasks:
- [x] Backup current directories (create .backup copies)
- [x] Move `.claude/checkpoints/*` to `.claude/data/checkpoints/` (3 files)
- [x] Move `.claude/logs/*` to `.claude/data/logs/` (4 files)
- [x] Move `.claude/registry/*` to `.claude/data/registry/` (51 files)
- [x] Verify all files migrated successfully (compare file counts)
- [x] Remove empty old directories after verification

Testing:
```bash
# Verify migration completeness
echo "Checkpoint files:"
find .claude/data/checkpoints -type f | wc -l
echo "Log files:"
find .claude/data/logs -type f | wc -l
echo "Registry files:"
find .claude/data/registry -type f | wc -l

# Verify old directories empty or removed
test ! -d .claude/checkpoints && echo "Old checkpoints removed" || ls -la .claude/checkpoints
test ! -d .claude/logs && echo "Old logs removed" || ls -la .claude/logs
test ! -d .claude/registry && echo "Old registry removed" || ls -la .claude/registry
```

### Phase 4: Update Documentation and References [COMPLETED]
**Objective**: Update all documentation to reference new directory structure
**Complexity**: Medium
**Risk**: Low (documentation only)

Tasks:
- [x] Update CLAUDE.md references to checkpoints/logs/registry paths
- [x] Update `.claude/data/README.md` with comprehensive structure documentation
- [x] Search for hardcoded path references in documentation files
- [x] Update command documentation (if any reference old paths)
- [x] Update test documentation to reflect new paths
- [x] Check `.gitignore` patterns (ensure .claude/data/ is gitignored)

Testing:
```bash
# Find any remaining references to old paths in documentation
grep -r "\.claude/checkpoints" .claude/docs/ .claude/specs/ CLAUDE.md || echo "No old checkpoint refs"
grep -r "\.claude/logs[^/]" .claude/docs/ .claude/specs/ CLAUDE.md || echo "No old log refs"
grep -r "\.claude/registry[^/]" .claude/docs/ .claude/specs/ CLAUDE.md || echo "No old registry refs"

# Verify gitignore coverage
grep -E "\.claude/(data|checkpoints|logs|registry)" .gitignore
```

### Phase 5: Run Full Test Suite
**Objective**: Verify all tests pass with new directory structure
**Complexity**: Low
**Risk**: Low (validates all changes work correctly)

Tasks:
- [ ] Run checkpoint-utils tests: `test_state_management.sh`
- [ ] Run logger tests (if any exist)
- [ ] Run artifact-operations tests (if any exist)
- [ ] Run full test suite: `.claude/tests/run_all_tests.sh`
- [ ] Verify no test failures related to path changes
- [ ] Check for any hardcoded path references in test files
- [ ] Update test assertions if they check specific paths

Testing:
```bash
# Run comprehensive test suite
cd .claude/tests
./run_all_tests.sh

# Specifically test checkpoint operations
./test_state_management.sh

# Test adaptive planning logger
./test_adaptive_planning.sh

# Check test files for old path references
grep -r "\.claude/checkpoints[^/]" .claude/tests/ || echo "No old checkpoint refs in tests"
grep -r "\.claude/logs[^/]" .claude/tests/ || echo "No old log refs in tests"
grep -r "\.claude/registry[^/]" .claude/tests/ || echo "No old registry refs in tests"
```

## Testing Strategy

### Unit Testing
- Verify each library file loads without errors after path updates
- Test checkpoint creation/loading with new paths
- Test log writing with new paths
- Test artifact registration with new paths

### Integration Testing
- Run full test suite to catch any missed path references
- Test command workflows that use checkpoints (e.g., /implement)
- Test logging during actual operations
- Verify artifact tracking still works

### Manual Verification
- Check that `.claude/examples/` remains unchanged
- Verify old directories are removed or empty
- Confirm `.claude/data/` structure is clean and organized
- Review `.gitignore` to ensure proper patterns

## Rollback Plan

If issues arise:
1. Restore backup directories (`.claude/checkpoints.backup`, etc.)
2. Revert library file changes (git checkout)
3. Remove migrated content from `.claude/data/` subdirectories
4. Run tests to verify rollback successful

## Documentation Requirements

### Primary Documentation Updates
1. **CLAUDE.md**: Update all references to checkpoint/log/registry paths
2. **.claude/data/README.md**: Document complete directory structure and purpose
3. **Command Documentation**: Update any commands that reference paths

### Documentation Sections to Update
- Testing Protocols section (checkpoint references)
- Adaptive Planning section (log file locations)
- Development Workflow section (artifact registry paths)

## Dependencies

- No external dependencies
- Requires shell utilities: mv, cp, mkdir, chmod
- Git for version control and rollback capability

## Risk Assessment

### Medium Risks
1. **Hardcoded Path References**: Missing a path reference could break functionality
   - Mitigation: Comprehensive grep search before and after changes
   - Validation: Full test suite execution

2. **Active Checkpoint Files**: Moving files that are currently in use
   - Mitigation: Perform migration when no commands are running
   - Validation: Verify file integrity after migration

3. **Test Path Assertions**: Tests may check for specific paths
   - Mitigation: Review all test files for path assertions
   - Validation: Update test expectations as needed

### Low Risks
1. **Documentation Updates**: Missing documentation references
   - Impact: Confusion but not functional breakage
   - Mitigation: Systematic grep-based search

## Notes

### Directory Purposes (Post-Migration)
- **checkpoints/**: Runtime state for resumable operations
- **logs/**: Structured logging for debugging and audit
- **registry/**: Artifact metadata tracking
- **metrics/**: Performance and analytics data (already in data/)
- **examples/**: Static code examples (stays at top level, tracked in git)

### Backward Compatibility
The old directory structure will be completely removed after migration. Commands and tests must use environment variables or the updated constants. No backward compatibility layer is needed since this is internal tooling.

### Future Improvements
- Consider making paths fully configurable via environment variables
- Add migration utility for future directory restructurings
- Document path configuration in `.claude/data/README.md`

---

## Spec Updater Checklist
- [ ] Ensure plan is in topic-based directory structure (specs/plans/)
- [ ] Create standard subdirectories if needed (N/A - single plan file)
- [ ] Update cross-references if artifacts moved (N/A)
- [ ] Create implementation summary when complete
- [ ] Verify gitignore compliance (.claude/data/ should be gitignored)

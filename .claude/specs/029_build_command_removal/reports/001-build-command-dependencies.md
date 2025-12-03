# Build Command Removal - Comprehensive Dependency Analysis

## Metadata
- **Date**: 2025-12-03
- **Research Complexity**: 3
- **Topic**: Build command removal from .claude/ system
- **Standards File**: /home/benjamin/.config/CLAUDE.md

---

## Executive Summary

The `/build` command is a **composite orchestrator** that combines functionality from `/implement` and `/test` commands. Removing it requires careful analysis because:

1. **No exclusive agents**: Both `implementer-coordinator` and `debug-analyst` are used by other commands
2. **Shared libraries**: All dependencies (workflow-state-machine.sh, state-persistence.sh, checkpoint-utils.sh) are core infrastructure
3. **Extensive documentation**: Over 25 files reference /build across guides, tests, and examples
4. **Alternative workflow exists**: The `/implement` + `/test` combination provides equivalent functionality

**Recommendation**: Safe to remove `/build` command file and update documentation. All dependencies must be retained as they are shared infrastructure.

---

## 1. Primary Artifacts to Remove

### 1.1 Command File (Primary Target)
- **File**: `/home/benjamin/.config/.claude/commands/build.md` (1945 lines)
- **Type**: Orchestrator command combining implement + test + debug phases
- **Safe to remove**: Yes
- **Action**: Delete file

### 1.2 Command Documentation
- **File**: `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (860 lines)
- **Type**: Comprehensive command guide with examples
- **Safe to remove**: Yes
- **Action**: Delete file

### 1.3 Test Files (Build-Specific)
Build-specific test files can be removed:

```
/home/benjamin/.config/.claude/tests/integration/test_build_iteration.sh
/home/benjamin/.config/.claude/tests/integration/test_build_iteration_barriers.sh
/home/benjamin/.config/.claude/tests/integration/test_build_error_patterns.sh
/home/benjamin/.config/.claude/tests/state/test_build_state_transitions.sh
/home/benjamin/.config/.claude/tests/commands/test_build_status_update.sh
/home/benjamin/.config/.claude/tests/commands/test_build_task_delegation.sh
```

**Total**: 6 test files
**Safe to remove**: Yes (all test `/build` command specifically)
**Action**: Delete all 6 files

### 1.4 Output Templates
- **File**: `/home/benjamin/.config/.claude/output/build-output.md`
- **Type**: Example build command output
- **Safe to remove**: Yes
- **Action**: Delete file

---

## 2. Agents Analysis (All SHARED - Must Keep)

### 2.1 implementer-coordinator Agent
- **File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
- **Used by**:
  - `/build` (being removed)
  - `/implement` (KEEP - implements plans without testing)
- **Model**: haiku-4.5
- **Purpose**: Wave-based parallel phase execution with dependency analysis
- **Safe to remove**: **NO** - Still used by `/implement` command
- **Action**: **KEEP** - Update references only

### 2.2 debug-analyst Agent
- **File**: `/home/benjamin/.config/.claude/agents/debug-analyst.md`
- **Used by**:
  - `/build` (being removed)
  - `/test` (KEEP - test execution and debug workflow)
  - `/debug` (KEEP - debug-focused workflow)
- **Model**: sonnet-4.5
- **Purpose**: Root cause analysis and bug fixing
- **Safe to remove**: **NO** - Still used by `/test` and `/debug` commands
- **Action**: **KEEP** - Update references only

### 2.3 test-executor Agent
Referenced by `/build` in documentation but NOT in dependent-agents frontmatter:
- **File**: `/home/benjamin/.config/.claude/agents/test-executor.md`
- **Used by**:
  - `/test` (primary user)
  - `/build` (via Task invocation, not frontmatter)
- **Safe to remove**: **NO** - Core test infrastructure
- **Action**: **KEEP**

---

## 3. Library Dependencies (All SHARED - Must Keep)

All libraries used by `/build` are **core infrastructure** used across multiple commands:

### 3.1 workflow-state-machine.sh
- **Path**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
- **Version**: 2.0.0
- **Used by**: `/plan`, `/research`, `/debug`, `/implement`, `/test`, `/build`, `/repair`, `/revise`
- **Defines build-specific states**:
  - `STATE_IMPLEMENT` (used by `/implement`)
  - `STATE_TEST` (used by `/test`)
  - `STATE_DEBUG` (used by `/debug`, `/test`)
  - `STATE_DOCUMENT` (shared state)
- **Safe to remove**: **NO** - Core state machine infrastructure
- **Action**: **KEEP** - States are shared across commands

### 3.2 state-persistence.sh
- **Path**: `/home/benjamin/.config/.claude/lib/core/state-persistence.sh`
- **Version**: >=1.5.0
- **Used by**: All orchestrator commands for workflow state management
- **Safe to remove**: **NO** - Core infrastructure
- **Action**: **KEEP**

### 3.3 checkpoint-utils.sh
- **Path**: `/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh`
- **Used by**: `/build`, `/implement`, `/test` (checkpoint management)
- **Build-specific references**:
  - `build_checkpoint.json` naming pattern
  - Referenced in 25+ files
- **Safe to remove**: **NO** - Shared checkpoint infrastructure
- **Action**: **KEEP** - Generic checkpoint utilities

### 3.4 checkbox-utils.sh
- **Path**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh`
- **Used by**: Plan progress tracking across all commands
- **Safe to remove**: **NO** - Core plan infrastructure
- **Action**: **KEEP**

### 3.5 error-handling.sh
- **Path**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- **Used by**: All commands for centralized error logging
- **Safe to remove**: **NO** - Core infrastructure
- **Action**: **KEEP**

### 3.6 library-version-check.sh
- **Path**: `/home/benjamin/.config/.claude/lib/core/library-version-check.sh`
- **Used by**: All commands requiring version validation
- **Safe to remove**: **NO** - Core infrastructure
- **Action**: **KEEP**

---

## 4. Documentation References to Update

### 4.1 CLAUDE.md (Root Configuration)
- **File**: `/home/benjamin/.config/CLAUDE.md`
- **References**: Line 26 mentions `/build` in workflow chain
- **Action**: Update section to show `/implement` + `/test` alternative

### 4.2 Commands README
- **File**: `/home/benjamin/.config/.claude/commands/README.md`
- **References**:
  - Lines 10, 26-30: Primary workflow description
  - Lines 110-156: /build command documentation
  - Lines 847-874: Hard barrier pattern references
- **Action**:
  - Remove `/build` from primary workflow chain
  - Delete /build section (lines 110-156)
  - Update hard barrier examples
  - Update command count (13 → 12)

### 4.3 Command Reference Documentation
- **File**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
- **References**: Full /build command specification
- **Action**: Remove /build entry, update cross-references

### 4.4 State Machine Documentation
Files referencing build workflow states:

```
/home/benjamin/.config/.claude/docs/reference/state-machine-transitions.md
/home/benjamin/.config/.claude/docs/architecture/state-orchestration-transitions.md
/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md
/home/benjamin/.config/.claude/docs/guides/orchestration/state-machine-migration-guide.md
/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md
```

**Action**: Update examples to use `/implement` or `/test` instead of `/build`

### 4.5 Workflow Guides
Files with /build workflow examples:

```
/home/benjamin/.config/.claude/docs/guides/workflows/implement-test-workflow.md
/home/benjamin/.config/.claude/docs/guides/migration/task-invocation-pattern-migration.md
/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md (troubleshooting examples)
/home/benjamin/.config/.claude/docs/guides/commands/implement-command-guide.md (see also section)
/home/benjamin/.config/.claude/docs/guides/commands/test-command-guide.md (see also section)
/home/benjamin/.config/.claude/docs/guides/commands/debug-command-guide.md (see also section)
```

**Action**: Replace /build examples with `/implement` + `/test` workflow

### 4.6 Pattern Documentation
Files referencing /build in pattern examples:

```
/home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md
```

**Action**: Update pattern examples to use other orchestrator commands

### 4.7 Architecture Documentation
Files with /build architectural references:

```
/home/benjamin/.config/.claude/docs/concepts/directory-organization.md
/home/benjamin/.config/.claude/docs/reference/standards/idempotent-state-transitions.md
/home/benjamin/.config/.claude/docs/architecture/hierarchical-supervisor-coordination.md
```

**Action**: Update architectural diagrams and examples

### 4.8 Agent Documentation
- **File**: `/home/benjamin/.config/.claude/agents/README.md`
- **References**: implementer-coordinator and debug-analyst usage
- **Action**: Remove /build from agent usage examples

### 4.9 Plan Progress Tracking
- **File**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md`
- **References**: Build command progress markers
- **Action**: Update examples to use /implement

---

## 5. Grep Results Analysis

### 5.1 Direct `/build` References
**Total files**: 100+ files match `/build` pattern

**Categories**:
1. **Test files** (6): Safe to remove
2. **Documentation** (25+): Update references
3. **Specs/reports** (50+): Historical records, no action needed
4. **Library code** (3): Generic checkpoint utilities, keep

### 5.2 "build workflow" / "build-from-plan" References
**Total files**: 25 files match case-insensitive pattern

**Key findings**:
- Most are documentation or historical spec files
- `/implement` provides equivalent functionality
- No hardcoded dependencies on "build" naming

---

## 6. Cross-Reference Check

### 6.1 State Machine Constants
Build workflow uses these state constants from workflow-state-machine.sh:

```bash
STATE_IMPLEMENT="implement"  # Used by /implement command
STATE_TEST="test"            # Used by /test command
STATE_DEBUG="debug"          # Used by /debug, /test commands
STATE_DOCUMENT="document"    # Shared state
STATE_COMPLETE="complete"    # Terminal state
```

**Impact**: All states are shared with other commands - NO removal needed

### 6.2 Checkpoint Naming Patterns
Build-specific checkpoint patterns:

```
build_checkpoint.json
build_${WORKFLOW_ID}
workflow_build_*.sh
```

**Impact**: Pattern-based, no hardcoded dependencies. Checkpoint utilities remain generic.

### 6.3 Workflow Type Classification
```bash
WORKFLOW_TYPE="full-implementation"  # /build specific
WORKFLOW_TYPE="implement-only"       # /implement
WORKFLOW_TYPE="test-and-debug"       # /test
```

**Impact**: Workflow types are configuration, not code dependencies. Safe to remove "full-implementation" references.

---

## 7. Alternative Workflow Recommendation

### 7.1 Replacement Pattern

**Current (with /build)**:
```bash
/plan "Add authentication"
/build  # Implements + tests + debugs
```

**Alternative (without /build)**:
```bash
/plan "Add authentication"
/implement  # Execute implementation phases
/test       # Run tests with debug loop
```

### 7.2 Advantages of Separation
1. **Clearer separation of concerns**: Implementation vs testing
2. **More flexible**: Can run implementation without tests
3. **Better debugging**: Can focus on test failures independently
4. **Reduced command complexity**: Each command does one thing well

### 7.3 Migration Path
Users can:
1. Replace `/build` calls with `/implement && /test`
2. Use `/implement` alone for test-later workflows
3. Use `/test` to retry failed tests without re-implementation

---

## 8. Orphaned Cruft Analysis

### 8.1 Files That Will Become Orphaned
**None**. All dependencies are shared infrastructure.

### 8.2 Dead Code in Shared Libraries
**Checkpoint utilities** contain build-specific examples but no dead code:
- Generic checkpoint save/load functions
- Pattern-based naming (any command can use)
- No hardcoded "build" logic

### 8.3 Obsolete Documentation Sections
After removal, these sections become obsolete:
1. CLAUDE.md: `/build` workflow chain references
2. Commands README: Build command documentation
3. Command guides: build-command-guide.md entire file
4. Pattern examples: Hard barrier examples using /build

**Action**: Clean removal with alternative examples

---

## 9. Summary of Removals

### 9.1 Safe to Remove (10 files)
```
.claude/commands/build.md
.claude/docs/guides/commands/build-command-guide.md
.claude/tests/integration/test_build_iteration.sh
.claude/tests/integration/test_build_iteration_barriers.sh
.claude/tests/integration/test_build_error_patterns.sh
.claude/tests/state/test_build_state_transitions.sh
.claude/tests/commands/test_build_status_update.sh
.claude/tests/commands/test_build_task_delegation.sh
.claude/output/build-output.md
```

### 9.2 Must Keep (All shared dependencies)
**Agents**:
- implementer-coordinator.md (used by /implement)
- debug-analyst.md (used by /test, /debug)
- test-executor.md (used by /test)

**Libraries**:
- workflow-state-machine.sh (core state infrastructure)
- state-persistence.sh (core persistence)
- checkpoint-utils.sh (shared checkpointing)
- checkbox-utils.sh (plan progress tracking)
- error-handling.sh (centralized error logging)
- library-version-check.sh (version validation)

### 9.3 Documentation Updates Required (25+ files)

**High Priority** (command infrastructure):
1. `/home/benjamin/.config/CLAUDE.md` - Update workflow chain
2. `.claude/commands/README.md` - Remove /build section, update count
3. `.claude/docs/reference/standards/command-reference.md` - Remove entry

**Medium Priority** (guides and examples):
4-10. State machine docs (5 files) - Update examples
11-16. Workflow guides (6 files) - Replace /build with alternatives
17-19. Pattern docs (3 files) - Update pattern examples
20-22. Architecture docs (3 files) - Update diagrams

**Low Priority** (cross-references):
23-25. Agent docs, plan progress docs, other guides

---

## 10. Implementation Plan Recommendations

### Phase 1: Validation
1. Verify all /build users can migrate to /implement + /test
2. Document migration path in removal plan
3. Test alternative workflow with existing specs

### Phase 2: File Removal
1. Delete 10 primary artifacts (command + guide + tests + output)
2. Commit removals with clear message

### Phase 3: Documentation Updates
1. Update CLAUDE.md workflow chain
2. Update commands README (remove section, update count)
3. Update command reference
4. Update state machine docs (5 files)
5. Update workflow guides (6 files)
6. Update pattern examples (3 files)
7. Update architecture docs (3 files)
8. Update cross-references (3 files)

### Phase 4: Verification
1. Run link validator to catch broken references
2. Check for remaining `/build` references with grep
3. Test that /implement and /test provide equivalent functionality
4. Update TODO.md to track completion

---

## 11. Risks and Mitigation

### Risk 1: User Confusion
**Risk**: Users accustomed to `/build` workflow may be confused
**Mitigation**:
- Add migration guide to docs
- Update CLAUDE.md with clear alternative
- Keep historical specs mentioning /build (context)

### Risk 2: Broken Documentation Links
**Risk**: Internal links to build-command-guide.md will break
**Mitigation**:
- Run validate-links-quick.sh after updates
- Update all cross-references in Phase 3
- Add redirect or alias documentation

### Risk 3: Test Coverage Loss
**Risk**: Removing 6 test files reduces coverage
**Mitigation**:
- Build-specific tests become irrelevant after removal
- /implement and /test have their own test coverage
- State machine tests cover shared infrastructure

---

## 12. Conclusion

The `/build` command can be **safely removed** with the following understanding:

**What to Remove**:
- 1 command file
- 1 comprehensive guide
- 6 test files
- 1 output template
- **Total**: 10 files

**What to Keep** (all shared):
- 3 agents (implementer-coordinator, debug-analyst, test-executor)
- 6 core libraries (state machine, persistence, checkpoints, errors, version check, checkbox utils)
- All agent behavioral guidelines
- All library utilities

**What to Update**:
- 25+ documentation files with /build references
- CLAUDE.md workflow chain
- Commands README (remove section, update count from 13 → 12)
- Cross-references and examples

**Alternative Workflow**:
Users can achieve equivalent functionality with:
```bash
/implement [plan-file]  # Execute implementation phases
/test [plan-file]       # Run tests with debug loop
```

This provides **better separation of concerns** and **more flexibility** than the composite /build command.

---

## Research Artifacts

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/build.md` (1945 lines)
- `/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md` (860 lines)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
- `/home/benjamin/.config/.claude/agents/debug-analyst.md`
- `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
- `/home/benjamin/.config/.claude/lib/workflow/checkpoint-utils.sh`
- 100+ files via grep patterns

### Search Patterns Used
1. `**/*build*` glob in commands/, agents/, tests/
2. `/build` grep across entire .claude/ directory
3. `build-from-plan|build workflow` case-insensitive grep
4. `implementer-coordinator|debug-analyst` grep
5. State constants analysis
6. Checkpoint pattern analysis

### Cross-References Validated
- Agent usage across commands (frontmatter analysis)
- Library dependencies (version requirements)
- State machine constants (shared vs unique)
- Checkpoint naming patterns (generic vs specific)
- Workflow type classifications

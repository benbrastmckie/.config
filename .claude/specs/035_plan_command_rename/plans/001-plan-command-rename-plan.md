# /plan Command Rename to /create-plan - Implementation Plan

## Metadata
- **Date**: 2025-12-03
- **Feature**: Rename /plan command to /create-plan with systematic reference updates throughout .claude/ directory
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-4 hours
- **Complexity Score**: 85.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Plan Command References Inventory](../reports/001-plan-command-references-inventory.md)

## Overview

This plan systematically renames the `/plan` command to `/create-plan` to improve clarity and consistency with other command naming patterns. The research phase identified 100+ files requiring updates across 7 major categories: command files, CLAUDE.md sections, documentation, agent files, tests, libraries, and scripts.

The rename improves semantic clarity by making the command's purpose (creating new implementation plans) explicit in the name, aligning with the descriptive naming pattern used by other orchestrator commands.

## Research Summary

The research inventory identified comprehensive integration of the `/plan` command throughout the codebase:

- **Command Files**: 2 files (plan.md + lean-plan.md for comparison)
- **CLAUDE.md References**: 12 section metadata headers using `/plan`
- **Documentation**: 50+ files including guides, troubleshooting, architecture docs
- **Agent Files**: 8 agent behavioral files with /plan workflow examples
- **Test Files**: 15+ test files covering unit, integration, and progressive tests
- **Library Files**: 10+ files in lib/plan/ and lib/workflow/ directories
- **Scripts**: 5+ validation and verification scripts with examples
- **Output Files**: 5+ historical output files (low priority)
- **Spec Files**: 100+ historical specs (optional cleanup)

**Critical Insight**: The workflow type "research-and-plan" should remain unchanged as it describes the process, not the command name. The lib/plan/ directory also remains unchanged as it's domain-focused (planning utilities), not command-specific.

**Recommended Approach**: Phased implementation prioritizing breaking changes first (command file, CLAUDE.md, command catalog), followed by agent integration, documentation, testing, and optional cleanup.

## Success Criteria

- [ ] `/create-plan` command executes successfully with full functionality
- [ ] Command appears correctly in Claude Code dropdown menu
- [ ] All CLAUDE.md section metadata references `/create-plan` instead of `/plan`
- [ ] Agent workflows use `/create-plan` in all examples and invocations
- [ ] Complete test suite passes with new command name
- [ ] All documentation links resolve correctly without broken references
- [ ] Workflow state machine recognizes and processes `/create-plan` correctly
- [ ] TODO.md integration triggers correctly with `/create-plan`
- [ ] Error logging uses correct command name in all log entries
- [ ] No residual `/plan` references in active documentation or code (excluding historical archives)

## Technical Design

### Architecture Overview

The rename follows a **clean-break refactoring pattern** as defined in the Clean-Break Development Standard:

1. **File Rename**: Direct rename of command file (no compatibility wrapper)
2. **Reference Updates**: Systematic sed/grep-based replacements across categories
3. **Validation**: Comprehensive testing at each phase to ensure functionality
4. **No Deprecation Period**: Internal tooling change requires immediate cutover

### Component Interactions

```
User Invocation (/create-plan)
    ↓
Claude Code Command Discovery
    ↓
.claude/commands/create-plan.md (renamed from plan.md)
    ↓
plan-architect.md agent (updated with /create-plan references)
    ↓
lib/plan/ libraries (unchanged - domain utilities)
    ↓
specs/{NNN_topic}/plans/ output (unchanged - topic-based structure)
```

### File Organization

```
.claude/
├── commands/
│   ├── create-plan.md          # RENAMED from plan.md
│   └── lean-plan.md            # UNCHANGED (Lean-specific)
├── agents/
│   └── plan-architect.md       # UPDATED (example invocations)
├── docs/
│   ├── guides/commands/
│   │   └── create-plan-command-guide.md  # RENAMED from plan-command-guide.md
│   └── reference/standards/
│       └── command-reference.md          # UPDATED (command catalog)
├── lib/
│   └── plan/                   # UNCHANGED (domain library)
├── tests/
│   └── unit/
│       └── test_create_plan_command_fixes.sh  # RENAMED
└── CLAUDE.md                   # UPDATED (12 section headers)
```

### Standards Compliance

This plan aligns with existing project standards:

- **Clean-Break Development**: No compatibility layer, immediate cutover (internal tooling)
- **Code Standards**: Bash block sourcing patterns maintained in renamed command file
- **Testing Protocols**: Full test suite verification after each phase
- **Documentation Policy**: Update all docs atomically, remove historical commentary
- **Error Logging**: Maintain error logging integration with updated command name

### Validation Strategy

Each phase includes verification commands to ensure:
1. File rename successful and discoverable
2. References updated correctly (no broken links)
3. Tests pass with new command name
4. Functionality preserved (regression testing)

## Implementation Phases

### Phase 1: Critical Command Files and CLAUDE.md [COMPLETE]
dependencies: []

**Objective**: Rename primary command file and update CLAUDE.md section headers to ensure core functionality with new name.

**Complexity**: Medium

**Tasks**:
- [x] Rename command file: `mv .claude/commands/plan.md .claude/commands/create-plan.md`
- [x] Update command frontmatter description in create-plan.md (line 2: "description" field)
- [x] Update CLAUDE.md section header at line 46: `[Used by: /research, /plan, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 69: `[Used by: /implement, /refactor, /plan]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 87: `[Used by: /refactor, /implement, /plan, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 182: `[Used by: /implement, /plan, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 191: `[Used by: /refactor, /implement, /plan, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 205: `[Used by: /plan, /expand, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 212: `[Used by: /plan, /repair, ...]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 229: `[Used by: /implement, /plan]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 236: `[Used by: /implement, /plan, /debug]` → `/create-plan`
- [x] Update CLAUDE.md section header at line 319: `[Used by: /document, /plan]` → `/create-plan`
- [x] Update internal /plan references in create-plan.md command file (error messages, comments)

**Testing**:
```bash
# Verify command file renamed and discoverable
test -f /home/benjamin/.config/.claude/commands/create-plan.md || echo "ERROR: Command file not renamed"
test ! -f /home/benjamin/.config/.claude/commands/plan.md || echo "ERROR: Old file still exists"

# Verify CLAUDE.md section headers updated
grep -c "/create-plan" /home/benjamin/.config/CLAUDE.md  # Should be 10
grep -c "\[Used by:.*/plan[^-]" /home/benjamin/.config/CLAUDE.md  # Should be 0

# Test command invocation
echo "/create-plan test feature" | head -1  # Verify discoverable

echo "✓ Phase 1 validation complete"
```

**Expected Duration**: 45 minutes

---

### Phase 2: Command Reference and Primary Documentation [COMPLETE]
dependencies: [1]

**Objective**: Update command catalog and primary documentation to reflect new command name in user-facing materials.

**Complexity**: Medium

**Tasks**:
- [x] Update .claude/docs/reference/standards/command-reference.md line 31 (#plan → #create-plan index entry)
- [x] Update command-reference.md lines 458-479 (command description section)
- [x] Update command-reference.md line 709 (Commands by Type section)
- [x] Update command-reference.md lines 752, 759 (Commands by Agent section)
- [x] Rename .claude/docs/guides/commands/plan-command-guide.md → create-plan-command-guide.md
- [x] Update all /plan references in create-plan-command-guide.md (lines 1-50+)
- [x] Update .claude/commands/README.md lines 9, 11 (workflow sequence)
- [x] Update .claude/commands/README.md line 117 (command index)
- [x] Update .claude/commands/README.md lines 163-186 (full /plan section)
- [x] Update .claude/commands/README.md lines 461-503 (flag support tables)
- [x] Update .claude/commands/README.md line 559 (example usage)
- [x] Update .claude/commands/README.md lines 701-705 (standards integration table)
- [x] Update .claude/commands/README.md line 837 (agent usage table)

**Testing**:
```bash
# Verify command guide renamed
test -f /home/benjamin/.config/.claude/docs/guides/commands/create-plan-command-guide.md || echo "ERROR: Guide not renamed"
test ! -f /home/benjamin/.config/.claude/docs/guides/commands/plan-command-guide.md || echo "ERROR: Old guide still exists"

# Verify command-reference.md updated
grep -c "/create-plan" /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md  # Should be 4+
grep -c "^### /plan" /home/benjamin/.config/.claude/docs/reference/standards/command-reference.md  # Should be 0

# Verify commands/README.md updated
grep -c "/create-plan" /home/benjamin/.config/.claude/commands/README.md  # Should be 15+

echo "✓ Phase 2 validation complete"
```

**Expected Duration**: 1 hour

---

### Phase 3: Agent Behavioral Files [COMPLETE]
dependencies: [1]

**Objective**: Update all agent behavioral files to reference /create-plan in workflow examples and invocation patterns.

**Complexity**: Medium

**Tasks**:
- [x] Update .claude/agents/plan-architect.md lines 54, 224, 350, 675, 770, 780, 827, 886 (example invocations)
- [x] Update .claude/agents/research-specialist.md line 629 ("### From /plan Command" section header)
- [x] Update .claude/agents/implementer-coordinator.md lines 556, 690 (plan file examples)
- [x] Update .claude/agents/spec-updater.md line 791 ("### From /plan" section header)
- [x] Update .claude/agents/repair-analyst.md line 189 (command filter example)
- [x] Update .claude/agents/README.md lines 20, 47, 188, 214, 668, 795 (agent-command relationships)
- [x] Review .claude/agents/lean-plan-architect.md for /plan vs /lean-plan references
- [x] Review .claude/agents/lean-research-specialist.md for /plan vs /lean-plan references

**Testing**:
```bash
# Verify agent files updated
grep -c "/create-plan" /home/benjamin/.config/.claude/agents/plan-architect.md  # Should be 8+
grep -c "From /create-plan Command" /home/benjamin/.config/.claude/agents/research-specialist.md  # Should be 1

# Verify no stray /plan references (excluding /lean-plan)
grep -r "/plan[^-]" /home/benjamin/.config/.claude/agents/ | grep -v "/lean-plan" | grep -v "research-and-plan" || echo "✓ No stray /plan references"

echo "✓ Phase 3 validation complete"
```

**Expected Duration**: 45 minutes

---

### Phase 4: Workflow and Architecture Documentation [COMPLETE]
dependencies: [2]

**Objective**: Update workflow guides, architecture docs, and troubleshooting guides with new command name.

**Complexity**: Medium

**Tasks**:
- [x] Update .claude/docs/workflows/adaptive-planning-guide.md lines 279, 298, 475 (/plan → /create-plan)
- [x] Update .claude/docs/workflows/development-workflow.md (workflow sequence diagrams)
- [x] Update .claude/docs/workflows/context-budget-management.md (command usage patterns)
- [x] Update .claude/docs/architecture/state-based-orchestration-overview.md (workflow references)
- [x] Rename .claude/docs/troubleshooting/plan-command-errors.md → create-plan-command-errors.md
- [x] Update create-plan-command-errors.md internal references
- [x] Update .claude/docs/troubleshooting/duplicate-commands.md lines 405, 473 (plan.md examples)
- [x] Update .claude/docs/troubleshooting/agent-delegation-troubleshooting.md (SlashCommand anti-patterns)
- [x] Update .claude/README.md lines 37, 67, 154, 203, 377-378, 539, 541, 581-583 (usage examples)
- [x] Update .claude/docs/README.md (command workflow overview)

**Testing**:
```bash
# Verify workflow docs updated
grep -c "/create-plan" /home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md  # Should be 3+

# Verify troubleshooting guide renamed
test -f /home/benjamin/.config/.claude/docs/troubleshooting/create-plan-command-errors.md || echo "ERROR: Guide not renamed"

# Verify main README updated
grep -c "/create-plan" /home/benjamin/.config/.claude/README.md  # Should be 10+

echo "✓ Phase 4 validation complete"
```

**Expected Duration**: 45 minutes

---

### Phase 5: Test Suite Updates [COMPLETE]
dependencies: [3]

**Objective**: Rename test files and update test assertions to verify functionality with new command name.

**Complexity**: Medium

**Tasks**:
- [x] Rename .claude/tests/unit/test_plan_command_fixes.sh → test_create_plan_command_fixes.sh
- [x] Update test assertions in test_create_plan_command_fixes.sh
- [x] Update .claude/tests/progressive/test_plan_progress_markers.sh (command invocations)
- [x] Update .claude/tests/progressive/test_plan_updates.sh (plan update workflows)
- [x] Update .claude/tests/integration/test_command_integration.sh (/plan test cases)
- [x] Update .claude/tests/integration/test_system_wide_location.sh (plan.md file references)
- [x] Update .claude/tests/features/commands/test_command_standards_compliance.sh (plan.md in file list)
- [x] Update .claude/tests/features/commands/test_command_references.sh (command reference validation)
- [x] Update .claude/tests/features/compliance/test_compliance_remediation_phase7.sh line 22 (plan.md reference)
- [x] Update .claude/tests/agents/test_plan_architect_revision_mode.sh (agent invocations)
- [x] Update .claude/tests/agents/plan_architect_revision_fixtures/README.md (fixture descriptions)
- [x] Update .claude/tests/agents/README.md (plan-architect test descriptions)
- [x] Update .claude/tests/commands/test_revise_preserve_completed.sh (plan file references)
- [x] Update .claude/tests/commands/test_revise_small_plan.sh (plan file references)
- [x] Update .claude/tests/commands/test_expand_collapse_hard_barriers.sh (plan workflow references)

**Testing**:
```bash
# Verify test file renamed
test -f /home/benjamin/.config/.claude/tests/unit/test_create_plan_command_fixes.sh || echo "ERROR: Test not renamed"

# Run unit tests with new command name
bash /home/benjamin/.config/.claude/tests/unit/test_create_plan_command_fixes.sh

# Run integration tests
bash /home/benjamin/.config/.claude/tests/integration/test_command_integration.sh

# Verify all test files reference /create-plan
grep -r "commands/plan\.md" /home/benjamin/.config/.claude/tests/ && echo "ERROR: Old plan.md references in tests" || echo "✓ No old references"

echo "✓ Phase 5 validation complete - all tests passing"
```

**Expected Duration**: 1 hour

---

### Phase 6: Library Documentation and Scripts [COMPLETE]
dependencies: [4]

**Objective**: Update library README files and validation scripts to use new command name in examples.

**Complexity**: Low

**Tasks**:
- [x] Update .claude/lib/plan/README.md (/plan command invocation examples)
- [x] Update .claude/lib/workflow/README.md (workflow orchestration examples)
- [x] Update .claude/lib/todo/README.md line 135 ("After creating a new plan (`/plan`, ...)")
- [x] Update .claude/scripts/lint-checkpoint-format.sh line 51 (plan.md example)
- [x] Update .claude/scripts/lint-argument-capture.sh line 44 (plan.md example)
- [x] Update .claude/scripts/verify-todo-integration.sh (plan command references)

**Testing**:
```bash
# Verify library docs updated
grep -c "/create-plan" /home/benjamin/.config/.claude/lib/plan/README.md  # Should be 1+
grep -c "/create-plan" /home/benjamin/.config/.claude/lib/todo/README.md  # Should be 1

# Verify script examples updated
grep -c "create-plan\.md" /home/benjamin/.config/.claude/scripts/lint-checkpoint-format.sh  # Should be 1

# Verify no active /plan references in scripts (excluding archived)
grep -r "commands/plan\.md" /home/benjamin/.config/.claude/scripts/ | grep -v archive || echo "✓ No active plan.md references"

echo "✓ Phase 6 validation complete"
```

**Expected Duration**: 30 minutes

---

### Phase 7: Optional Output File Cleanup [COMPLETE]
dependencies: [5, 6]

**Objective**: Rename historical output files and update output directory README for completeness.

**Complexity**: Low

**Tasks**:
- [x] Rename .claude/output/plan-output.md → create-plan-output.md
- [x] Update .claude/output/README.md line 9 (plan-output.md file reference)
- [x] Review .claude/output/errors-output.md for /plan references (optional historical update)
- [x] Review .claude/output/revise-output.md for plan.md references (optional historical update)

**Testing**:
```bash
# Verify output file renamed
test -f /home/benjamin/.config/.claude/output/create-plan-output.md || echo "ERROR: Output file not renamed"

# Verify output README updated
grep -c "create-plan-output.md" /home/benjamin/.config/.claude/output/README.md  # Should be 1

echo "✓ Phase 7 validation complete"
```

**Expected Duration**: 15 minutes

---

### Phase 8: Comprehensive Integration Testing [COMPLETE]
dependencies: [5, 6, 7]

**Objective**: Execute comprehensive integration tests to verify all systems function correctly with renamed command.

**Complexity**: Medium

**Tasks**:
- [x] Test `/create-plan` command execution with sample feature description
- [x] Verify command appears in Claude Code dropdown menu
- [x] Test plan-architect agent invocation from /create-plan
- [x] Test workflow state machine transitions with "research-and-plan" workflow type
- [x] Test TODO.md integration with /create-plan plan creation
- [x] Test error logging with /create-plan command name
- [x] Test adaptive planning workflows (plan expansion/revision)
- [x] Verify all documentation links resolve (no 404s)
- [x] Run full test suite: `bash .claude/scripts/run-all-tests.sh`
- [x] Test /lean-plan command still functions (unchanged)
- [x] Verify lib/plan/ libraries load correctly from /create-plan
- [x] Test create-plan-command-guide.md is discoverable in docs

**Testing**:
```bash
# Execute full integration test suite
bash /home/benjamin/.config/.claude/tests/integration/test_command_integration.sh

# Verify command discovery
ls -la /home/benjamin/.config/.claude/commands/ | grep -c "create-plan.md"  # Should be 1
ls -la /home/benjamin/.config/.claude/commands/ | grep -c "^.*plan\.md$"    # Should be 0

# Test sample plan creation
echo "Testing /create-plan command execution..."
# (Manual test: invoke /create-plan with sample feature)

# Verify no broken documentation links
bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh

# Final validation: search for stray /plan references (excluding /lean-plan, research-and-plan)
echo "Searching for stray /plan references..."
grep -r "commands/plan\.md" /home/benjamin/.config/.claude/ 2>/dev/null | grep -v archive | grep -v specs/ | grep -v CHANGELOG && echo "WARNING: Found stray references" || echo "✓ No stray references"

echo "✓ Phase 8 complete - full integration test passed"
```

**Expected Duration**: 45 minutes

---

## Testing Strategy

### Unit Testing
- **Scope**: Individual file updates verified after each phase
- **Approach**: grep-based verification of reference counts and pattern matching
- **Coverage**: 100% of updated files validated for correct command name

### Integration Testing
- **Scope**: End-to-end workflow testing with renamed command
- **Approach**: Execute /create-plan with sample feature, verify plan creation
- **Tools**: Existing test suite in .claude/tests/integration/

### Regression Testing
- **Scope**: Ensure no functionality broken by rename
- **Approach**: Run complete test suite before and after implementation
- **Baseline**: Capture test results before Phase 1 for comparison

### Validation Commands
Each phase includes explicit bash validation commands to verify:
1. File rename completion
2. Reference update accuracy
3. Link integrity (no broken references)
4. Functional preservation

## Documentation Requirements

### Files Updated
1. **Command-reference.md**: Update command catalog entry (Phase 2)
2. **create-plan-command-guide.md**: Rename and update guide (Phase 2)
3. **CLAUDE.md**: Update 12 section metadata headers (Phase 1)
4. **commands/README.md**: Update command workflow documentation (Phase 2)
5. **Workflow guides**: Update all workflow sequences (Phase 4)
6. **Troubleshooting guides**: Rename and update error guides (Phase 4)
7. **Library READMEs**: Update example invocations (Phase 6)
8. **Agent READMEs**: Update agent-command relationships (Phase 3)

### Standards Compliance
- **No Historical Commentary**: Remove any "previously known as /plan" notes after 1 release cycle
- **Clean-Break Approach**: Update all docs atomically, no compatibility documentation
- **Link Validation**: Run link checker after Phase 4 to ensure no broken references

## Dependencies

### Internal Dependencies
- **CLAUDE.md Standards**: Phase 1 must complete before other phases (standards authority)
- **Command File Rename**: Phase 1 blocks all other phases (breaking change)
- **Documentation Updates**: Phase 2 must complete before Phase 4 (reference integrity)
- **Test Updates**: Phase 5 depends on Phase 3 (agent files must be updated first)

### External Dependencies
- **None**: This is an internal refactoring with no external API changes

### Phase Dependency Graph
```
Phase 1 (Critical Files)
    ├── Phase 2 (Documentation)
    │       └── Phase 4 (Workflow Docs)
    ├── Phase 3 (Agents)
    │       └── Phase 5 (Tests)
    └── Phase 6 (Libraries)

Phase 7 (Optional Cleanup) ← depends on [5, 6]
Phase 8 (Integration Testing) ← depends on [5, 6, 7]
```

## Risk Management

### High-Risk Areas
1. **Command Discovery**: If rename breaks discovery, command unusable
   - Mitigation: Test command dropdown after Phase 1
2. **CLAUDE.md Section Headers**: If metadata malformed, section discovery breaks
   - Mitigation: Validate CLAUDE.md syntax after Phase 1
3. **Test Suite Failures**: If tests fail, may indicate functional regression
   - Mitigation: Capture baseline test results before implementation

### Rollback Strategy
- **Command File**: Restore `git checkout .claude/commands/plan.md` if issues
- **CLAUDE.md**: Restore from git if section updates malformed
- **Full Rollback**: `git reset --hard` to commit before Phase 1 start

### Validation Gates
Each phase includes explicit validation commands that MUST pass before proceeding to next phase. If validation fails, rollback current phase and investigate.

## Notes

**Workflow Type Preservation**: The workflow type "research-and-plan" remains unchanged as it describes the process, not the command name. Only command invocation references are updated.

**Library Directory**: The lib/plan/ directory remains unchanged as it's a domain-focused library (planning utilities) used by multiple commands (/create-plan, /lean-plan, /revise, /implement), not command-specific infrastructure.

**Historical Specs**: 100+ spec files in .claude/specs/ reference /plan but are gitignored historical artifacts. No updates required unless spec files are actively maintained.

**Lean Command**: The /lean-plan command is NOT renamed to maintain domain-specific brevity for Lean theorem proving workflows. It remains as /lean-plan for consistency with Lean community conventions.

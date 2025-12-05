# /plan Command References - Complete Inventory

**Research Date**: 2025-12-03
**Research Complexity**: 3
**Workflow Type**: research-and-plan
**Purpose**: Comprehensive inventory of all /plan command references for systematic rename to /create-plan

---

## Executive Summary

This research identifies **ALL references** to the `/plan` command throughout the `.claude/` directory structure. The rename from `/plan` to `/create-plan` requires systematic updates across 7 major categories:

1. **Command Files** (2 files)
2. **Documentation** (50+ files)
3. **Agent Files** (8 files)
4. **Test Files** (15+ files)
5. **CLAUDE.md Sections** (12 references)
6. **Library Files** (plan/ directory references)
7. **Historical Spec Files** (100+ files - optional cleanup)

**Estimated Impact**: HIGH - The /plan command is deeply integrated throughout the codebase as a primary workflow command.

---

## Category 1: Command Files (CRITICAL)

### Primary Command File
**File**: `/home/benjamin/.config/.claude/commands/plan.md`
- **Lines**: 1500+ lines
- **Type**: Orchestrator command (research-and-plan workflow)
- **Rename Action**: Rename file to `create-plan.md`
- **Content Updates Required**:
  - Frontmatter `description` field
  - All `/plan` references in comments and documentation
  - Command type designation
  - Error messages mentioning `/plan`

### Related Command File
**File**: `/home/benjamin/.config/.claude/commands/lean-plan.md`
- **Lines**: 57000+ bytes
- **Type**: Lean-specific planning command
- **Decision**: Consider renaming to `/lean-create-plan` for consistency
- **Alternative**: Keep as `/lean-plan` (Lean domain-specific naming)

---

## Category 2: Documentation Files (HIGH PRIORITY)

### Command Reference Documentation

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
- **Lines**: 31, 349-350, 458-479, 709, 752, 759
- **Updates Required**:
  - Update command index entry (#plan → #create-plan)
  - Update command description section (lines 458-479)
  - Update "Commands by Type" section (line 709)
  - Update "Commands by Agent" section (line 752, 759)
  - Archive note for old /plan command location (line 356)

### Command Guide Documentation

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/plan-command-guide.md`
- **Decision**: Rename to `create-plan-command-guide.md`
- **Content**: Complete rewrite of all /plan references
- **Lines**: 1-50 (all references to "/plan" throughout)

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/README.md`
- **References**: Multiple in command workflow descriptions
- **Updates**: Change workflow sequence from "/plan" to "/create-plan"

### Command Development Documentation

**File**: `/home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md`
- **References**: Examples using /plan command
- **Updates**: Update all example invocations

**File**: `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md`
- **References**: `/plan` as orchestrator example
- **Updates**: Change example references to /create-plan

### Workflow Documentation

**File**: `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md`
- **Line 279**: "Use /plan to create initial plan"
- **Line 298**: "**Plan Early**: Use /plan to establish structure"
- **Line 475**: Link to plan command

**File**: `/home/benjamin/.config/.claude/docs/workflows/development-workflow.md`
- **References**: /plan in workflow sequence diagrams
- **Updates**: Update workflow examples

**File**: `/home/benjamin/.config/.claude/docs/workflows/context-budget-management.md`
- **References**: /plan command usage patterns
- **Updates**: Update command examples

### Architecture Documentation

**File**: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`
- **References**: State machine transitions for /plan workflow
- **Updates**: Update workflow type references

**File**: `/home/benjamin/.config/.claude/docs/reference/state-machine-transitions.md`
- **References**: "research-and-plan" workflow type
- **Updates**: State transition documentation

### Troubleshooting Documentation

**File**: `/home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md`
- **Lines 405, 473**: Examples using plan.md
- **Updates**: Update example file references

**File**: `/home/benjamin/.config/.claude/docs/troubleshooting/plan-command-errors.md`
- **Entire File**: Dedicated to /plan command errors
- **Decision**: Rename to `create-plan-command-errors.md`

**File**: `/home/benjamin/.config/.claude/docs/troubleshooting/agent-delegation-troubleshooting.md`
- **References**: SlashCommand invocations of /plan
- **Updates**: Update anti-pattern examples

### Other Documentation

**File**: `/home/benjamin/.config/.claude/README.md`
- **Lines 37, 67, 154, 203, 377-378, 539, 541, 581-583**
- **References**: Multiple /plan command examples
- **Updates**: All usage examples and command listings

**File**: `/home/benjamin/.config/.claude/CHANGELOG.md`
- **Lines 60, 67, 97, 104, 107, 127, 144, 184, 202, 206, 259**
- **Historical References**: Past changes to /plan command
- **Decision**: Keep historical references as-is (already in past)

**File**: `/home/benjamin/.config/.claude/docs/README.md`
- **References**: /plan in command workflow overview
- **Updates**: Update workflow diagrams

---

## Category 3: CLAUDE.md References (CRITICAL)

**File**: `/home/benjamin/.config/CLAUDE.md`

### Section Updates Required:

1. **Line 46**: Directory Protocols section header
   - `[Used by: /research, /plan, /implement, ...]`
   - **Update**: Change to `/create-plan`

2. **Line 69**: Code Standards section header
   - `[Used by: /implement, /refactor, /plan]`
   - **Update**: Change to `/create-plan`

3. **Line 87**: Clean-Break Development section header
   - `[Used by: /refactor, /implement, /plan, all development commands]`
   - **Update**: Change to `/create-plan`

4. **Line 154**: Error Logging Standards section header
   - `[Used by: all commands, all agents, /implement, /debug, /errors, /repair]`
   - **Note**: Does not explicitly mention /plan (no change needed)

5. **Line 182**: Directory Organization Standards section header
   - `[Used by: /implement, /plan, /refactor, all development commands]`
   - **Update**: Change to `/create-plan`

6. **Line 191**: Development Philosophy section header
   - `[Used by: /refactor, /implement, /plan, /document]`
   - **Update**: Change to `/create-plan`

7. **Line 205**: Adaptive Planning Configuration section header
   - `[Used by: /plan, /expand, /implement, /revise]`
   - **Update**: Change to `/create-plan`

8. **Line 212**: Plan Metadata Standard section header
   - `[Used by: /plan, /repair, /revise, /debug, plan-architect]`
   - **Update**: Change to `/create-plan`

9. **Line 229**: Development Workflow section header
   - `[Used by: /implement, /plan]`
   - **Update**: Change to `/create-plan`

10. **Line 236**: Hierarchical Agent Architecture section header
    - `[Used by: /implement, /plan, /debug]`
    - **Update**: Change to `/create-plan`

11. **Line 319**: Documentation Policy section header
    - `[Used by: /document, /plan]`
    - **Update**: Change to `/create-plan`

12. **Line 296**: Project-Specific Commands section
    - **References**: Command Reference link (indirect)
    - **Update**: Already handled via command-reference.md updates

---

## Category 4: Agent Files (HIGH PRIORITY)

### Plan Architect Agent
**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`
- **Lines**: 54, 224, 350, 675, 770, 780, 827, 886
- **References**: Multiple examples using /plan command context
- **Updates**: Update all example invocations and workflow descriptions

### Research Specialist Agent
**File**: `/home/benjamin/.config/.claude/agents/research-specialist.md`
- **Line 629**: "### From /plan Command" section header
- **Updates**: Update section header and command reference

### Implementation Coordinator Agent
**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
- **Lines**: 556, 690
- **References**: Plan file parameter examples
- **Updates**: Update example file paths if needed

### Spec Updater Agent
**File**: `/home/benjamin/.config/.claude/agents/spec-updater.md`
- **Line 791**: "### From /plan (Creating Topic Structure)" section
- **Updates**: Update section header

### Lean-Specific Agents
**File**: `/home/benjamin/.config/.claude/agents/lean-plan-architect.md`
- **References**: Lean planning workflow
- **Decision**: May reference /lean-plan instead of /plan

**File**: `/home/benjamin/.config/.claude/agents/lean-research-specialist.md`
- **References**: Lean-specific planning context
- **Decision**: Check for /plan vs /lean-plan references

### Other Agents
**File**: `/home/benjamin/.config/.claude/agents/repair-analyst.md`
- **Line 189**: Command filter example using "/plan"
- **Updates**: Update example command name

**File**: `/home/benjamin/.config/.claude/agents/README.md`
- **Lines**: 20, 47, 188, 214, 668, 795
- **References**: Multiple agent-command relationship descriptions
- **Updates**: Update all /plan references to /create-plan

---

## Category 5: Test Files (MEDIUM PRIORITY)

### Unit Tests
**File**: `/home/benjamin/.config/.claude/tests/unit/test_plan_command_fixes.sh`
- **Decision**: Rename to `test_create_plan_command_fixes.sh`
- **Content**: Update all test cases referencing /plan

### Progressive Planning Tests
**File**: `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh`
- **References**: Plan progress tracking tests
- **Updates**: Update command invocations

**File**: `/home/benjamin/.config/.claude/tests/progressive/test_plan_updates.sh`
- **References**: Plan update workflows
- **Updates**: Update test scenarios

### Integration Tests
**File**: `/home/benjamin/.config/.claude/tests/integration/test_command_integration.sh`
- **References**: Command integration testing
- **Updates**: Update /plan command test cases

**File**: `/home/benjamin/.config/.claude/tests/integration/test_system_wide_location.sh`
- **References**: System-wide command location tests
- **Updates**: Update plan.md file references

### Feature Tests
**File**: `/home/benjamin/.config/.claude/tests/features/commands/test_command_standards_compliance.sh`
- **References**: Standards compliance checks for commands
- **Updates**: Update plan.md in test file list

**File**: `/home/benjamin/.config/.claude/tests/features/commands/test_command_references.sh`
- **References**: Command reference validation
- **Updates**: Update plan command references

**File**: `/home/benjamin/.config/.claude/tests/features/compliance/test_compliance_remediation_phase7.sh`
- **Line 22**: References plan.md for compliance testing
- **Updates**: Update file path

### Agent Tests
**File**: `/home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh`
- **References**: Plan architect agent testing
- **Updates**: Update agent invocation examples

**File**: `/home/benjamin/.config/.claude/tests/agents/plan_architect_revision_fixtures/README.md`
- **References**: Test fixture documentation
- **Updates**: Update fixture descriptions

**File**: `/home/benjamin/.config/.claude/tests/agents/README.md`
- **References**: Agent testing overview
- **Updates**: Update plan-architect test descriptions

### Command Tests
**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_preserve_completed.sh`
- **References**: Plan revision testing
- **Updates**: Update plan file references

**File**: `/home/benjamin/.config/.claude/tests/commands/test_revise_small_plan.sh`
- **References**: Small plan revision testing
- **Updates**: Update plan file references

**File**: `/home/benjamin/.config/.claude/tests/commands/test_expand_collapse_hard_barriers.sh`
- **References**: Plan expansion/collapse testing
- **Updates**: Update plan workflow references

---

## Category 6: Library Files (MEDIUM PRIORITY)

### Plan Library Directory
**Directory**: `/home/benjamin/.config/.claude/lib/plan/`

**Files**:
- `checkbox-utils.sh` - Plan checkbox utilities
- `plan-core-bundle.sh` - Core planning functions
- `topic-utils.sh` - Topic-based plan organization
- `complexity-utils.sh` - Plan complexity assessment
- `auto-analysis-utils.sh` - Plan analysis automation
- `parse-template.sh` - Plan template parsing
- `topic-decomposition.sh` - Plan decomposition utilities
- `standards-extraction.sh` - Standards extraction for plans

**Decision**: Keep directory name as `lib/plan/` (domain terminology, not command-specific)
- Libraries are domain-focused (planning), not command-specific
- Multiple commands use these libraries (/create-plan, /lean-plan, /revise, /implement)
- No rename required for library directory

**File Updates Required**:
- **lib/plan/README.md**: Update references to /plan command → /create-plan
- **Internal documentation**: Update command invocation examples

### Workflow Library References
**File**: `/home/benjamin/.config/.claude/lib/workflow/README.md`
- **References**: Mentions /plan as workflow orchestration example
- **Updates**: Update command examples

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh`
- **References**: "research-and-plan" workflow type
- **Updates**: Update workflow type constants/documentation

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-scope-detection.sh`
- **References**: Plan workflow pattern detection
- **Updates**: Update pattern matching for new command name

**File**: `/home/benjamin/.config/.claude/lib/workflow/workflow-llm-classifier.sh`
- **References**: Workflow classification patterns
- **Updates**: Update classifier training examples

---

## Category 7: Scripts (MEDIUM PRIORITY)

### Validation Scripts
**File**: `/home/benjamin/.config/.claude/scripts/lint-checkpoint-format.sh`
- **Line 51**: Example using plan.md
- **Updates**: Update example file reference

**File**: `/home/benjamin/.config/.claude/scripts/lint-argument-capture.sh`
- **Line 44**: Example using plan.md
- **Updates**: Update example file reference

### Verification Scripts
**File**: `/home/benjamin/.config/.claude/scripts/verify-todo-integration.sh`
- **References**: Plan command in TODO integration checks
- **Updates**: Update command name references

---

## Category 8: Output Files (LOW PRIORITY - Optional)

### Command Output Files
**File**: `/home/benjamin/.config/.claude/output/plan-output.md`
- **Decision**: Rename to `create-plan-output.md`
- **Content**: Historical output (can be regenerated)

**File**: `/home/benjamin/.config/.claude/output/README.md`
- **Line 9**: References plan-output.md
- **Updates**: Update file reference

### Other Output Files
**File**: `/home/benjamin/.config/.claude/output/errors-output.md`
- **Lines**: 1, 5, 10, 24 - References to /plan in error analysis
- **Decision**: Historical data (optional update)

**File**: `/home/benjamin/.config/.claude/output/revise-output.md`
- **Lines**: Multiple references to plan.md in revision history
- **Decision**: Historical data (optional update)

---

## Category 9: Spec Files (LOW PRIORITY - Historical)

### Active Specs (Keep for traceability)
**Recent Specs** (Past 30 days):
- `031_plan_command_format_fix/` - Plan format standardization
- `032_lean_plan_command/` - Lean planning implementation
- `034_lean_command_naming_standardization/` - Lean command naming

**Decision**: Keep historical references as-is (already completed work)

### Archived/Historical Specs
**Count**: 100+ spec files referencing /plan
**Examples**:
- `992_repair_plan_20251201_123734/` - Plan error repairs
- `997_plan_metadata_field_deficiency/` - Plan metadata standards
- `013_plan_command_dropdown_duplicates/` - Plan command discovery issues
- Many others in specs/ directory

**Decision**: No updates required (historical artifacts, gitignored)

---

## Category 10: README Files

**File**: `/home/benjamin/.config/.claude/commands/README.md`
- **Lines**: 9, 11, 117, 163-186, 461, 475, 481, 490, 496, 503, 559, 701, 704-705, 837, 906
- **References**: Extensive /plan command documentation
- **Updates Required**:
  - Command workflow sequence (line 9, 11)
  - Command index (line 117)
  - Full /plan section (lines 163-186)
  - Flag support tables (lines 461-503)
  - Example usage (line 559)
  - Standards integration table (lines 701-705)
  - Agent usage table (line 837)

**File**: `/home/benjamin/.config/.claude/lib/plan/README.md`
- **References**: Plan library usage and /plan command examples
- **Updates**: Update command invocation examples

**File**: `/home/benjamin/.config/.claude/lib/todo/README.md`
- **Line 135**: "After creating a new plan (`/plan`, `/repair`, `/debug`)"
- **Updates**: Change /plan to /create-plan

---

## Special Considerations

### Workflow Type: "research-and-plan"
**Files Affected**:
- `lib/workflow/workflow-state-machine.sh`
- `lib/workflow/workflow-scope-detection.sh`
- `lib/workflow/workflow-llm-classifier.sh`
- `commands/plan.md` (frontmatter)
- Documentation referencing workflow types

**Decision**: Keep workflow type as "research-and-plan" (descriptive of process, not command name)

### Archive Location References
**File**: `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
- **Line 356**: "Archive Location: `.claude/archive/legacy-workflow-commands/commands/plan.md`"
- **Decision**: This is already documenting OLD archived /plan - no change needed
- **Action**: Add NEW archive note for the rename in command history

### SlashCommand Invocations
**Pattern**: `SlashCommand.*/(plan|implement|debug)`
**Files**: Multiple documentation files showing anti-patterns
**Decision**: Update examples to use /create-plan where showing correct usage

---

## Implementation Strategy Recommendations

### Phase 1: Critical Files (Breaking Changes)
1. Rename `/home/benjamin/.config/.claude/commands/plan.md` → `create-plan.md`
2. Update CLAUDE.md section headers (12 references)
3. Update command-reference.md (primary command catalog)
4. Update commands/README.md (command workflow documentation)

### Phase 2: Agent Integration
1. Update plan-architect.md (primary planning agent)
2. Update research-specialist.md (research workflow)
3. Update agents/README.md (agent-command relationships)

### Phase 3: Documentation
1. Rename plan-command-guide.md → create-plan-command-guide.md
2. Update all workflow documentation
3. Update troubleshooting guides
4. Update architecture documentation

### Phase 4: Testing
1. Rename test files
2. Update test assertions
3. Update test fixtures
4. Verify all tests pass

### Phase 5: Libraries & Scripts
1. Update lib/plan/README.md
2. Update workflow library documentation
3. Update validation script examples

### Phase 6: Optional Cleanup
1. Rename output files
2. Update historical references (low priority)
3. Clean up old spec files (optional)

---

## Breaking Changes Analysis

### High Impact (Users Must Update)
1. **Command Invocation**: `/plan` → `/create-plan` in all user workflows
2. **Documentation Links**: Any bookmarked docs with /plan references
3. **Custom Scripts**: Any user scripts calling /plan directly

### Medium Impact (Automated Migration Possible)
1. **CLAUDE.md**: Section header metadata updates
2. **Agent Context**: Agents referencing /plan in behavioral files
3. **Test Suites**: Test files and assertions

### Low Impact (Internal Only)
1. **Library Documentation**: Examples in library READMEs
2. **Historical Specs**: Past implementation artifacts
3. **Output Files**: Command execution logs

---

## File Count Summary

| Category | File Count | Update Priority |
|----------|-----------|----------------|
| Command Files | 2 | CRITICAL |
| CLAUDE.md Sections | 12 | CRITICAL |
| Documentation Files | 50+ | HIGH |
| Agent Files | 8 | HIGH |
| Test Files | 15+ | MEDIUM |
| Library Files | 10+ | MEDIUM |
| Script Files | 5+ | MEDIUM |
| Output Files | 5+ | LOW |
| Spec Files (historical) | 100+ | LOW (optional) |

**Total Files Requiring Updates**: ~100 files (excluding historical specs)

---

## Search Patterns Used

```bash
# Primary searches conducted:
grep -r "/plan" .claude/
grep -r "plan\.md" .claude/
grep -ri "plan command" .claude/
grep -r "commands/plan" .claude/
grep -r "research-and-plan" .claude/
grep -r "plan-architect" .claude/

# File discovery:
find .claude -name "*plan*.md" -type f
find .claude -name "*plan*.sh" -type f
ls -la .claude/commands/ | grep plan
```

---

## Validation Checklist

After rename implementation, verify:

- [ ] `/create-plan` command executes successfully
- [ ] Command appears in Claude Code dropdown menu
- [ ] CLAUDE.md section metadata correctly references /create-plan
- [ ] All agent workflows use /create-plan in examples
- [ ] Test suite passes with new command name
- [ ] Documentation links resolve correctly
- [ ] Workflow state machine recognizes new command
- [ ] TODO.md updates trigger correctly with /create-plan
- [ ] Error logging uses correct command name
- [ ] Adaptive planning workflows function correctly

---

## Related Commands (Consistency Check)

Commands that should be reviewed for naming consistency:
- `/lean-plan` - Consider renaming to `/lean-create-plan`?
- `/revise` - Already distinct (plan modification vs creation)
- `/repair` - Already distinct (error-focused planning)
- `/research` - Already distinct (research-only, no plan)
- `/implement` - Already distinct (plan execution)

**Recommendation**: Keep `/lean-plan` as-is (Lean theorem proving is domain-specific, shorter name acceptable)

---

## Git History Notes

Recent commits mentioning /plan:
- `6d17dfbb` - "created fix for plan"
- `19cf76a3` - "about to refactor /plan"
- `6e1ce8b8` - "fix(plan): Fix CLAUDE_PROJECT_DIR init order"
- `82739f4d` - "fix(plan): Enforce three-tier library sourcing"
- Multiple error repair commits

**Recommendation**: Add migration commit clearly documenting the rename for future reference.

---

## Conclusion

The /plan command is deeply integrated throughout the `.claude/` system as a primary workflow orchestrator. Renaming to `/create-plan` requires systematic updates across 100+ files in 7 major categories. The highest priority updates are:

1. **Command file rename** (breaking change)
2. **CLAUDE.md section updates** (standards compliance)
3. **Command reference documentation** (user-facing)
4. **Agent behavioral files** (workflow integration)

Historical spec files and output artifacts can be updated optionally or left as-is for traceability.

**Estimated Implementation Time**: 3-4 hours for comprehensive rename with testing.

---

**Report Generated**: 2025-12-03
**Researcher**: research-specialist agent
**Complexity Level**: 3 (Comprehensive research)
**Next Steps**: Create implementation plan using this inventory

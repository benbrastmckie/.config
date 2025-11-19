# Commands and Infrastructure Standards Compliance Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Bring all commands and supporting infrastructure to full compliance with architectural standards
- **Scope**: 17 commands, 60+ library files, 16 architectural standards
- **Estimated Phases**: 8
- **Estimated Hours**: 24-32
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 132 (Tier 2 - Phase directory expansion available via `/expand`)
- **Research Reports**:
  - [Command Standards Compliance Report](/home/benjamin/.config/.claude/specs/758_research_all_commands_and_their_supporting_infrast/reports/001_command_standards_compliance.md)

## Overview

This implementation plan addresses the findings from the command standards compliance research report to bring all 17 commands and their supporting infrastructure into full compliance with the 16 architectural standards defined in `.claude/docs/reference/command_architecture_standards.md`.

**Primary Goals**:
1. Fix critical issues in debug.md (undefined functions, missing library sourcing)
2. Complete Standard 14 compliance (guide files for all commands)
3. Implement return code verification (Standard 16) across all commands
4. Standardize library sourcing order (Standard 15) in all commands
5. Add VERIFICATION CHECKPOINTs (Standard 0) where missing
6. Strengthen imperative language patterns across commands
7. Update command reference documentation
8. Create automated validation test suite

## Research Summary

The research report analyzed 17 commands and 60+ supporting libraries against 16 architectural standards, revealing:

- **High compliance (85-95%)**: coordinate.md, plan.md, research.md, implement.md
- **Moderate compliance (60-75%)**: debug.md, setup.md, and several others needing review
- **Critical gaps**: debug.md has undefined functions, missing library sourcing
- **Standard 14 violations**: 5 commands missing guide files
- **Standard 16 violations**: 55% compliance on return code verification
- **Standard 15 violations**: Inconsistent library sourcing order

**Recommended approach**: Address critical issues first (debug.md), then systematically improve compliance from highest to lowest impact standards.

## Success Criteria

- [ ] All 17 commands pass automated compliance validation tests
- [ ] debug.md critical issues fully resolved (undefined functions, missing sourcing)
- [ ] 100% of commands have companion guide files (Standard 14)
- [ ] 100% critical function calls have return code verification (Standard 16)
- [ ] 100% of commands with multiple bash blocks source libraries correctly (Standard 15)
- [ ] All commands have MANDATORY VERIFICATION checkpoints for file creation
- [ ] Automated test suite validates all 16 standards
- [ ] Command reference documentation updated with all commands and cross-references

## Technical Design

### Architecture Overview

The compliance remediation follows a layered approach:

1. **Library Layer**: Create missing utility functions (debug-utils.sh)
2. **Command Layer**: Update commands to source libraries and verify return codes
3. **Documentation Layer**: Create missing guide files and update references
4. **Validation Layer**: Automated tests for ongoing compliance checking

### Component Interactions

```
.claude/
├── lib/
│   ├── debug-utils.sh (NEW)           # Missing functions for debug.md
│   ├── verification-helpers.sh        # Enhanced verification patterns
│   └── ... existing libraries
├── commands/
│   ├── debug.md (CRITICAL FIX)
│   ├── setup.md (FIX)
│   ├── ... other commands
├── docs/
│   ├── guides/
│   │   ├── expand-command-guide.md (NEW)
│   │   ├── collapse-command-guide.md (NEW)
│   │   ├── convert-docs-command-guide.md (NEW)
│   │   ├── revise-command-guide.md (NEW)
│   │   ├── research-command-guide.md (NEW)
│   │   └── coordinate-command-guide.md (NEW)
│   └── reference/
│       └── command-reference.md (UPDATE)
└── tests/
    ├── test_command_standards_compliance.sh (NEW)
    ├── test_library_sourcing_order.sh (NEW)
    ├── test_verification_checkpoints.sh (NEW)
    └── test_return_code_verification.sh (NEW)
```

### Standards Compliance Matrix

| Standard | Target | Implementation |
|----------|--------|----------------|
| Standard 0 | 100% | VERIFICATION CHECKPOINTs in all commands |
| Standard 0.5 | 100% | Agent prompts with STEP dependencies |
| Standard 13 | 100% | CLAUDE_PROJECT_DIR detection in all commands |
| Standard 14 | 100% | Guide files for all commands |
| Standard 15 | 100% | Library sourcing order in all commands |
| Standard 16 | 100% | Return code verification in all commands |

## Implementation Phases

### Phase 1: Critical debug.md Fixes
dependencies: []

**Objective**: Resolve all critical issues in debug.md that cause runtime errors

**Complexity**: High
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/lib/debug-utils.sh` with missing functions:
  - [ ] Implement `analyze_issue()` function
  - [ ] Implement `calculate_issue_complexity()` function
  - [ ] Implement `determine_root_cause()` function
  - [ ] Implement `verify_root_cause()` function
- [ ] Add source guard and documentation to debug-utils.sh
- [ ] Update `/home/benjamin/.config/.claude/commands/debug.md`:
  - [ ] Add Standard 13 project directory detection at file start
  - [ ] Add library sourcing block per Standard 15 order
  - [ ] Source debug-utils.sh after core libraries
  - [ ] Add MANDATORY VERIFICATION checkpoint after report creation
  - [ ] Add return code verification for all critical functions
  - [ ] Add explicit path injection for Task invocations
- [ ] Test debug.md execution with sample issue

Testing:
```bash
# Verify library sources correctly
bash -n .claude/lib/debug-utils.sh

# Test debug.md compliance
.claude/tests/test_command_standards_compliance.sh debug.md
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 1 - Critical debug.md Fixes`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Complete Standard 14 - Create Missing Guide Files
dependencies: []

**Objective**: Create companion guide files for all commands missing them

**Complexity**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Read `/home/benjamin/.config/.claude/docs/guides/_template-command-guide.md` for structure
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/expand-command-guide.md`:
  - [ ] Document command syntax and options
  - [ ] Add usage examples and common scenarios
  - [ ] Include troubleshooting section
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/collapse-command-guide.md`:
  - [ ] Document collapse operations and modes
  - [ ] Add examples of phase/stage collapsing
  - [ ] Include interaction with expand command
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/convert-docs-command-guide.md`:
  - [ ] Document supported format conversions
  - [ ] Add examples for Markdown, Word, PDF
  - [ ] Include agent mode documentation
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/revise-command-guide.md`:
  - [ ] Document revision workflow
  - [ ] Add interactive and automated mode examples
  - [ ] Include context handling documentation
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/research-command-guide.md`:
  - [ ] Document hierarchical research pattern
  - [ ] Add examples of topic decomposition
  - [ ] Include synthesis documentation
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`:
  - [ ] Document state machine orchestration
  - [ ] Add workflow examples
  - [ ] Include phase execution patterns

Testing:
```bash
# Verify all guide files exist
for cmd in expand collapse convert-docs revise research coordinate; do
  test -f ".claude/docs/guides/${cmd}-command-guide.md" && echo "OK: $cmd" || echo "MISSING: $cmd"
done
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 2 - Create Missing Guide Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Implement Return Code Verification (Standard 16)
dependencies: [1]

**Objective**: Add return code verification for all critical function calls across commands

**Complexity**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Audit `/home/benjamin/.config/.claude/commands/debug.md` for unverified function calls
- [ ] Audit `/home/benjamin/.config/.claude/commands/setup.md` for unverified function calls
- [ ] Audit `/home/benjamin/.config/.claude/commands/fix.md` for unverified function calls
- [ ] Audit `/home/benjamin/.config/.claude/commands/build.md` for unverified function calls

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update debug.md with explicit return code checks:
  - [ ] Add `if ! function_call; then ... fi` pattern
  - [ ] Add error messages with diagnostic information
  - [ ] Add exit codes for failure cases
- [ ] Update setup.md with explicit return code checks:
  - [ ] Fix early exit issues (lines 77, 144, 178)
  - [ ] Add comprehensive error handling
- [ ] Update fix.md with explicit return code checks
- [ ] Update build.md with explicit return code checks

Testing:
```bash
# Verify return code patterns in commands
for cmd in debug setup fix build; do
  echo "Checking $cmd.md..."
  grep -c "if ! " ".claude/commands/${cmd}.md" || echo "WARN: No return code checks"
done
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 3 - Return Code Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Standardize Library Sourcing Order (Standard 15)
dependencies: [1]

**Objective**: Ensure all commands source libraries in correct dependency order

**Complexity**: Low
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Create standardized sourcing block template:
  ```bash
  LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
  source "${LIB_DIR}/workflow-state-machine.sh"
  source "${LIB_DIR}/state-persistence.sh"
  source "${LIB_DIR}/error-handling.sh"
  source "${LIB_DIR}/verification-helpers.sh"
  ```
- [ ] Update `/home/benjamin/.config/.claude/commands/debug.md` with standard sourcing block
- [ ] Update `/home/benjamin/.config/.claude/commands/setup.md` with standard sourcing block (enhance existing)
- [ ] Review and update all other commands for sourcing order compliance:
  - [ ] fix.md
  - [ ] build.md
  - [ ] expand.md
  - [ ] collapse.md
  - [ ] revise.md
  - [ ] convert-docs.md

Testing:
```bash
# Create test for sourcing order
.claude/tests/test_library_sourcing_order.sh
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 4 - Library Sourcing Order`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Add VERIFICATION CHECKPOINTs (Standard 0)
dependencies: [1, 3]

**Objective**: Add mandatory verification checkpoints where missing

**Complexity**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/commands/debug.md`:
  - [ ] Add MANDATORY VERIFICATION after debug report creation
  - [ ] Add checkpoint after artifact path calculation
- [ ] Update `/home/benjamin/.config/.claude/commands/setup.md`:
  - [ ] Add MANDATORY VERIFICATION after each mode operation
  - [ ] Add checkpoint for CLAUDE.md modifications
  - [ ] Add checkpoint for analysis report creation

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Review and add verification checkpoints to:
  - [ ] fix.md - after fix application
  - [ ] build.md - after each phase
  - [ ] expand.md - after expansion
  - [ ] collapse.md - after collapse
  - [ ] revise.md - after plan revision

Testing:
```bash
# Verify verification patterns present
.claude/tests/test_verification_checkpoints.sh
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 5 - VERIFICATION CHECKPOINTs`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Strengthen Imperative Language
dependencies: [1]

**Objective**: Convert weak descriptive language to imperative enforcement patterns

**Complexity**: Low
**Estimated Time**: 2 hours

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/commands/debug.md`:
  - [ ] Convert "should" to "MUST"
  - [ ] Convert "may" to "WILL"
  - [ ] Add "YOU MUST" directives for critical steps
  - [ ] Add "EXECUTE NOW" markers for bash blocks
- [ ] Update `/home/benjamin/.config/.claude/commands/setup.md`:
  - [ ] Convert weak language patterns
  - [ ] Add imperative markers for phase descriptions
- [ ] Review other commands for weak language patterns:
  - [ ] fix.md
  - [ ] build.md
  - [ ] revise.md
  - [ ] convert-docs.md

Testing:
```bash
# Check for remaining weak patterns
for cmd in debug setup fix build revise convert-docs; do
  echo "=== $cmd.md ==="
  grep -n "should\|may\|can\|might" ".claude/commands/${cmd}.md" | head -5
done
```

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 6 - Imperative Language`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 7: Create Automated Validation Test Suite
dependencies: [1, 2, 3, 4, 5]

**Objective**: Create comprehensive test suite for ongoing compliance validation

**Complexity**: High
**Estimated Time**: 4-5 hours

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`:
  - [ ] Implement Standard 0 validation (imperative language)
  - [ ] Implement Standard 13 validation (project directory detection)
  - [ ] Implement Standard 14 validation (guide files exist)
  - [ ] Implement Standard 15 validation (library sourcing order)
  - [ ] Implement Standard 16 validation (return code verification)
  - [ ] Add summary report output

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Create `/home/benjamin/.config/.claude/tests/test_library_sourcing_order.sh`:
  - [ ] Verify sourcing dependency order
  - [ ] Check for missing library sources
  - [ ] Validate source guard patterns
- [ ] Create `/home/benjamin/.config/.claude/tests/test_verification_checkpoints.sh`:
  - [ ] Count verification checkpoints per command
  - [ ] Validate checkpoint patterns
  - [ ] Report missing verifications
- [ ] Create `/home/benjamin/.config/.claude/tests/test_return_code_verification.sh`:
  - [ ] Identify critical function calls
  - [ ] Verify return code checking patterns
  - [ ] Report unverified calls
- [ ] Add test runner script to execute all compliance tests

Testing:
```bash
# Run full compliance test suite
bash .claude/tests/test_command_standards_compliance.sh

# Verify all tests pass
for test in test_library_sourcing_order test_verification_checkpoints test_return_code_verification; do
  bash ".claude/tests/${test}.sh" && echo "PASS: $test" || echo "FAIL: $test"
done
```

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 7 - Validation Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 8: Update Documentation and Final Validation
dependencies: [2, 7]

**Objective**: Update command reference documentation and perform final validation

**Complexity**: Low
**Estimated Time**: 2 hours

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-reference.md`:
  - [ ] Verify all 17 commands listed with correct descriptions
  - [ ] Add guide file cross-references for each command
  - [ ] Update status indicators for compliance
  - [ ] Add optimize-claude command if missing
- [ ] Run full compliance test suite on all commands:
  - [ ] Execute test_command_standards_compliance.sh
  - [ ] Verify 100% compliance score
  - [ ] Document any remaining issues
- [ ] Create compliance summary report:
  - [ ] List all standards and compliance status
  - [ ] Document any deferred items
  - [ ] Note maintenance recommendations
- [ ] Update this plan with final completion status

Testing:
```bash
# Full validation run
echo "=== Final Compliance Validation ==="
bash .claude/tests/test_command_standards_compliance.sh

# Verify guide files for all commands
echo "=== Guide File Verification ==="
for cmd in $(ls .claude/commands/*.md | xargs -n1 basename | sed 's/.md//'); do
  [ "$cmd" == "README" ] && continue
  test -f ".claude/docs/guides/${cmd}-command-guide.md" && echo "OK: $cmd" || echo "MISSING: $cmd"
done
```

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(758): complete Phase 8 - Documentation and Final Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Each new library function has isolated tests
- debug-utils.sh functions tested with sample inputs
- Validation scripts tested with known-good and known-bad commands

### Integration Testing
- Full command execution after modifications
- Verify artifacts created at expected locations
- Cross-command workflows (e.g., plan -> implement -> debug)

### Compliance Testing
- Automated test suite validates all 16 standards
- Run on every command modification
- CI/CD integration recommended

### Test Commands
```bash
# Run all compliance tests
.claude/tests/test_command_standards_compliance.sh

# Test individual standards
.claude/tests/test_library_sourcing_order.sh
.claude/tests/test_verification_checkpoints.sh
.claude/tests/test_return_code_verification.sh

# Verify debug.md specifically (critical fix)
bash -n .claude/lib/debug-utils.sh
.claude/tests/test_command_standards_compliance.sh debug.md
```

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Add guide cross-references
- Individual command files - Add guide file references in metadata

### Files to Create
- 6 new guide files (expand, collapse, convert-docs, revise, research, coordinate)
- 4 new test files (compliance tests)
- 1 new library file (debug-utils.sh)

### Documentation Standards
- Follow template at `_template-command-guide.md`
- Include syntax, examples, troubleshooting
- Cross-reference related commands
- No emojis per documentation policy

## Dependencies

### External Dependencies
None - all work is within .claude/ directory

### Internal Dependencies
- Phase 3, 4, 5 depend on Phase 1 (debug.md must be fixed first)
- Phase 5 depends on Phase 3 (return codes before verification)
- Phase 7 depends on Phases 1-5 (can't test until fixes applied)
- Phase 8 depends on Phases 2 and 7 (docs and tests complete)

### Prerequisites
- Access to all command files in `.claude/commands/`
- Access to library files in `.claude/lib/`
- Access to documentation in `.claude/docs/`

## Risk Management

### Technical Risks

**Risk 1**: Breaking working commands during updates
- **Mitigation**: Test each command after modification
- **Mitigation**: Use version control for easy rollback
- **Impact**: High if not mitigated

**Risk 2**: Incomplete undefined function implementations
- **Mitigation**: Study existing similar patterns in codebase
- **Mitigation**: Start with stub implementations, iterate
- **Impact**: Medium - debug.md won't work without these

**Risk 3**: Test suite false positives/negatives
- **Mitigation**: Manual validation of test results
- **Mitigation**: Test on known-good commands first
- **Impact**: Low - can iterate on tests

### Rollback Strategy
- Commit after each phase completes
- Test before committing
- Use `git stash` for work in progress
- Document all changes for easy reversion

## Notes

- Phases 1, 2, 4, and 6 have no dependencies and can run in parallel
- Phase 7 requires most other phases complete (testing all fixes)
- Consider `/expand` if any phase proves too complex during implementation
- debug.md is highest priority - blocks testing of many workflows

# Plan Command Orchestration Fix - Implementation Plan

## Metadata
- **Date**: 2025-12-02 (Revised)
- **Feature**: Fix pseudo-code Task invocations across all workflow commands (system-wide)
- **Scope**: Audit and fix all 7 workflow commands in .claude/commands/ using incorrect Task invocation patterns
- **Estimated Phases**: 6
- **Estimated Hours**: 21-28 hours (increased from 18-24 to include agent file fixes)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 132.5 (increased from 87.5 due to 7 commands with 16+ Task invocations)
- **Structure Level**: 0
- **Research Reports**:
  - [Plan Command Orchestration Failure Analysis](../reports/001-plan-command-orchestration-failure.md)
  - [Command Orchestration Review - Cross-Command Analysis](../reports/command_orchestration_review.md)
  - [Agent Task Invocation Violations Analysis](../reports/003-agent-violations-analysis.md)

## Overview

**System-Wide Issue**: All 7 workflow commands (/plan, /build, /debug, /implement, /repair, /research, /revise, /test) fail to properly delegate to subagents because they use pseudo-code `Task { ... }` syntax that Claude does not recognize as actual tool invocations. This causes orchestrators with permissive tool access (Read, Write, Grep, Glob) to bypass delegation and perform subagent work directly, defeating the architectural purpose of context isolation and agent specialization.

**Scope**: 16+ broken Task invocations across 7 commands, affecting every major workflow in the system.

This plan systematically fixes all affected commands by replacing pseudo-code Task invocations with imperative Task tool invocation instructions, adds validation to detect the pattern, and updates documentation standards.

## Research Summary

Key findings from the research reports:

**Original Analysis** (001-plan-command-orchestration-failure.md):
1. **Root Cause**: The `Task { ... }` pseudo-code format is NOT recognized as actual tool calls by Claude. Claude's tool invocations require imperative instructions like "**EXECUTE NOW**: USE the Task tool...", not pseudo-code syntax.

2. **Partial Fix Applied**: Commit 0b710aff fixed supervise.md by replacing YAML-style Task blocks with imperative bullet-point instructions ("**EXECUTE NOW**: USE the Task tool with these parameters:"), but this fix was not applied to other commands.

3. **Bypass Mechanism**: Permissive `allowed-tools` (Read, Write, Grep, Glob) enables orchestrators to do subagent work directly when pseudo-code invocations fail to trigger actual Task tool calls.

4. **Architectural Impact**: 40-60% higher context usage in orchestrators, no logic reusability, unpredictable delegation, and difficult testing.

**Cross-Command Analysis** (command_orchestration_review.md):
1. **System-Wide Scope**: ALL 7 workflow commands suffer from the same issue (not just /plan):
   - /build (4 Task invocations) - CRITICAL
   - /debug (4 Task invocations) - CRITICAL
   - /implement (2 Task invocations + iteration loop) - CRITICAL
   - /repair (2 Task invocations) - HIGH
   - /research (2 Task invocations) - MEDIUM-HIGH
   - /revise (2 Task invocations) - HIGH
   - /test (2 Task invocations with DIFFERENT syntax) - MEDIUM-HIGH

2. **Edge Cases Identified**:
   - **Iteration Loop Pattern**: /implement and /test use iteration loops requiring multiple Task invocations
   - **Instructional Text Pattern**: /test uses instructional comments instead of pseudo-code Task blocks (different manifestation of same issue)
   - **Conditional Invocations**: /build and /test have conditional agent invocations (e.g., debug-analyst only if tests fail)

3. **Template Inheritance**: All commands appear to use a common template with pseudo-code syntax that was copied across the codebase without propagating the supervise.md fix.

## Success Criteria

- [ ] All 7 workflow commands using pseudo-code Task invocations are fixed with imperative pattern
- [ ] All 16+ Task invocations across commands use correct syntax
- [ ] Edge cases handled: iteration loops (/implement), instructional text (/test), conditional invocations (/build)
- [ ] All 33 agent file Task invocation violations are fixed with imperative pattern
- [ ] Agent example sections consistently demonstrate correct Task invocation syntax
- [ ] Template files fixed to prevent propagation of incorrect patterns to new agents
- [ ] Validation script detects incorrect Task invocation patterns in commands and agents
- [ ] Validation script detects instructional text pattern and iteration loop contexts
- [ ] Hard barrier delegation pattern documentation updated with Task invocation requirements
- [ ] Command authoring standards explicitly forbid pseudo-code Task syntax
- [ ] Pre-commit hooks prevent future pseudo-code Task invocations
- [ ] Test suite validates proper delegation behavior for all workflow commands
- [ ] All affected commands and agents pass hard barrier compliance validation
- [ ] Zero regression in existing command functionality

## Technical Design

### Architecture

The fix transforms pseudo-code Task invocations into imperative instructions that Claude recognizes as mandatory tool calls:

**Current (Broken)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION}"
  prompt: "..."
}
```

**Fixed (Imperative)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Output Directory: ${RESEARCH_DIR}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### Key Pattern Changes

1. **Imperative Directive**: Add "**EXECUTE NOW**: USE the Task tool..." before every Task invocation
2. **Mandatory Creation Notice**: Add "with mandatory file creation" to descriptions
3. **Remove Code Block Wrappers**: Task invocations should NOT be inside ``` ``` code blocks
4. **Explicit Instructions**: Make it clear this is a tool call, not documentation

### Validation Strategy

1. **Linter**: Create `lint-task-invocation-pattern.sh` to detect pseudo-code Task blocks without imperative directives
2. **Hard Barrier Validator**: Update `validate-hard-barrier-compliance.sh` to check for imperative Task directives
3. **Pre-commit Hook**: Integrate both validators into pre-commit workflow
4. **Test Suite**: Add integration tests verifying actual agent delegation occurs

### Documentation Updates

1. **Hard Barrier Pattern**: Add explicit Task invocation requirements to pattern documentation
2. **Command Authoring Standards**: Explicitly forbid pseudo-code Task syntax without imperative directives
3. **Command Patterns Quick Reference**: Add Task invocation template

## Implementation Phases

### Phase 1: Audit and Classify Affected Commands [COMPLETE]
dependencies: []

**Objective**: Identify all commands with pseudo-code Task invocations and classify by delegation pattern

**Complexity**: Low

**Tasks**:
- [x] Run grep to find all commands with `Task {` pattern (file: all .claude/commands/*.md)
- [x] For each command, categorize invocations: topic-naming, research, planning, debug, errors, collapse/expand
- [x] Identify commands using hard barrier pattern vs other patterns
- [x] Document current state of each command (has EXECUTE NOW directive? has CRITICAL BARRIER label?)
- [x] Create audit report with command → invocation count → pattern type mapping (file: .claude/specs/006_plan_command_orchestration_fix/reports/002-audit-report.md)
- [x] Prioritize fix order: high-usage commands first (plan, research, revise, build, debug)

**Testing**:
```bash
# Verify audit report exists and has comprehensive data
test -f .claude/specs/006_plan_command_orchestration_fix/reports/002-audit-report.md
grep -q "plan.md" .claude/specs/006_plan_command_orchestration_fix/reports/002-audit-report.md
grep -q "Total Commands" .claude/specs/006_plan_command_orchestration_fix/reports/002-audit-report.md
```

**Expected Duration**: 2 hours

### Phase 2: Fix High-Priority Orchestrator Commands [COMPLETE]
dependencies: [1]

**Objective**: Apply imperative Task invocation pattern to all high-priority workflow commands (build, debug, plan, repair, research, revise)

**Complexity**: High

**Tasks**:
- [x] Fix build.md: Replace 4 Task invocations (implementer-coordinator line 515, spec-updater line 1083, test-executor line 1245, debug-analyst line 1605) with imperative pattern (file: .claude/commands/build.md)
- [x] Fix debug.md: Replace 4 Task invocations (topic-naming line 322, research-specialist line 659, plan-architect line 946, debug-analyst line 1203) with imperative pattern (file: .claude/commands/debug.md)
- [x] Fix plan.md: Replace 3 Task invocations (topic-naming, research-specialist, plan-architect) with imperative pattern (file: .claude/commands/plan.md)
- [x] Fix repair.md: Replace 2 Task invocations (repair-analyst line 503, plan-architect line 1159) with imperative pattern (file: .claude/commands/repair.md)
- [x] Fix research.md: Replace 2 Task invocations (topic-naming line 368, research-specialist line 841) with imperative pattern (file: .claude/commands/research.md)
- [x] Fix revise.md: Replace 2 Task invocations (research-specialist line 623, plan-architect line 1053) with imperative pattern (file: .claude/commands/revise.md)
- [x] Verify each fix follows supervise.md pattern from commit 0b710aff
- [x] Test each command manually to confirm delegation occurs
- [x] Document any behavioral changes observed after fixes

**Pattern Template** (from supervise.md fix):
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "[Description] with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context Field 1]: ${VAR1}
    - [Context Field 2]: ${VAR2}
    - Output Path: ${OUTPUT_PATH}

    Execute [action] per behavioral guidelines.
    Return: [SIGNAL]: ${OUTPUT_PATH}
```

**Testing**:
```bash
# Verify each command file contains EXECUTE NOW directives
for cmd in build debug plan repair research revise; do
  grep -q "EXECUTE NOW.*Task tool" .claude/commands/$cmd.md || echo "FAILED: $cmd.md"
done

# Verify no naked Task { blocks remain (should have EXECUTE NOW before them)
for cmd in build debug plan repair research revise; do
  if grep -q "^Task {" .claude/commands/$cmd.md; then
    grep -B2 "^Task {" .claude/commands/$cmd.md | grep -q "EXECUTE NOW" || echo "FAILED: $cmd.md has naked Task block"
  fi
done

# Test each command delegation (manual verification)
# Expected: respective agents invoked (not inline work), artifacts created at expected paths
# /build: implementer-coordinator, test-executor invoked
# /debug: all 4 agents invoked sequentially
# /plan: research-specialist and plan-architect invoked
# /repair: repair-analyst and plan-architect invoked
# /research: topic-naming and research-specialist invoked
# /revise: research-specialist and plan-architect invoked
```

**Expected Duration**: 8 hours (increased from 6 due to 6 commands, 17 Task invocations)

### Phase 3: Fix Edge Case Commands (Iteration Loops, Instructional Text) [COMPLETE]
dependencies: [2]

**Objective**: Apply imperative pattern to /implement (iteration loop) and /test (instructional text), plus remaining utility commands

**Complexity**: Medium-High

**Tasks**:
- [x] Fix implement.md: Replace 2 Task invocations with imperative pattern (implementer-coordinator line 514, iteration re-invocation line 944) - NOTE: iteration loop pattern requires fixing SAME invocation twice (file: .claude/commands/implement.md)
- [x] Fix test.md: Convert instructional text to imperative Task invocations (test-executor line 388, debug-analyst line 618) - NOTE: different syntax, requires conversion from comments to Task blocks (file: .claude/commands/test.md)
- [x] Fix errors.md: Replace errors-analyst invocations with imperative pattern (file: .claude/commands/errors.md)
- [x] Fix expand.md: Replace plan-architect invocations with imperative pattern (file: .claude/commands/expand.md)
- [x] Fix collapse.md: Replace plan-architect/complexity-estimator invocations with imperative pattern (file: .claude/commands/collapse.md)
- [x] Fix setup.md: Replace topic-naming-agent invocations with imperative pattern (file: .claude/commands/setup.md)
- [x] Fix convert-docs.md: Replace any doc-converter agent invocations with imperative pattern (file: .claude/commands/convert-docs.md)
- [x] Fix optimize-claude.md: Replace any Task invocations with imperative pattern (file: .claude/commands/optimize-claude.md)
- [x] Fix todo.md: Replace todo-analyzer invocations with imperative pattern (file: .claude/commands/todo.md)
- [x] Test each command for proper delegation behavior
- [x] Check for any backup files (*.md.backup.*) that also need fixing

**Special Handling**:
- **/implement iteration loop**: The same Task invocation appears twice (initial invocation and loop re-invocation). Both instances must be fixed with imperative directive.
- **/test instructional text**: Convert instructional comments like "# Use the Task tool to invoke..." to actual imperative Task invocations with proper Task block syntax.

**Testing**:
```bash
# Verify no commands have naked Task { blocks without EXECUTE NOW
find .claude/commands -name "*.md" -not -name "README.md" -not -name "*backup*" \
  -exec sh -c 'grep -l "^Task {" "$1" | while read f; do
    grep -B2 "^Task {" "$f" | grep -q "EXECUTE NOW" || echo "FAILED: $f"
  done' _ {} \;

# Verify /test has proper Task blocks (not just instructional comments)
grep -q "^Task {" .claude/commands/test.md || echo "FAILED: test.md missing Task blocks"

# Verify /implement has both Task invocations fixed
IMPL_TASK_COUNT=$(grep -c "^Task {" .claude/commands/implement.md)
[ "$IMPL_TASK_COUNT" -eq 2 ] || echo "FAILED: implement.md should have 2 Task blocks (found: $IMPL_TASK_COUNT)"

# Run hard barrier compliance validator
bash .claude/scripts/validate-hard-barrier-compliance.sh --verbose
```

**Expected Duration**: 5 hours (increased from 4 due to edge case complexity)

### Phase 4: Create Validation and Enforcement Tools [COMPLETE]
dependencies: [3]

**Objective**: Add automated validation to prevent future pseudo-code Task invocations and detect edge case patterns

**Complexity**: Medium

**Tasks**:
- [x] Create lint-task-invocation-pattern.sh linter script (file: .claude/scripts/lint-task-invocation-pattern.sh)
  - Detect `Task {` blocks without "EXECUTE NOW" directive within 2 lines before
  - Detect instructional text patterns (e.g., "# Use the Task tool to invoke...") without actual Task invocation
  - Detect iteration loop contexts requiring multiple Task invocation fixes
  - Return ERROR-level violation for any naked Task blocks or instructional text patterns
  - Support --staged flag for pre-commit mode
  - Output format consistent with other linters (check-library-sourcing.sh pattern)
- [x] Update validate-hard-barrier-compliance.sh to check for imperative Task directives (file: .claude/scripts/validate-hard-barrier-compliance.sh)
  - Add Check 11: "Imperative Task Directives" - verify EXECUTE NOW before Task blocks
  - Add Check 12: "No Instructional Text Patterns" - verify no commented Task tool instructions without actual invocations
  - Update compliance scoring to include Task invocation pattern
- [x] Integrate lint-task-invocation-pattern.sh into validate-all-standards.sh (file: .claude/scripts/validate-all-standards.sh)
  - Add --task-invocation flag
  - Include in --all validation
- [x] Update pre-commit hook to run task invocation linter (file: .git/hooks/pre-commit)
  - Add lint-task-invocation-pattern.sh call
  - Block commits with ERROR-level violations
- [x] Create test suite for linter (file: .claude/tests/validators/test_lint_task_invocation.sh)
  - Test detection of naked Task blocks
  - Test detection of instructional text patterns
  - Test acceptance of properly prefixed Task blocks
  - Test false positive prevention (Task blocks in documentation sections)
  - Test iteration loop detection

**Testing**:
```bash
# Test linter detects violations
echo 'Task { subagent: "test" }' > /tmp/test_bad.md
bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test_bad.md
# Expected: ERROR reported

# Test linter detects instructional text pattern
echo '# Use the Task tool to invoke the agent' > /tmp/test_instructional.md
bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test_instructional.md
# Expected: ERROR reported

# Test linter accepts correct pattern
cat > /tmp/test_good.md << 'EOF'
**EXECUTE NOW**: USE the Task tool

Task { subagent: "test" }
EOF
bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test_good.md
# Expected: No errors

# Run linter test suite
bash .claude/tests/validators/test_lint_task_invocation.sh

# Verify integration with validate-all-standards
bash .claude/scripts/validate-all-standards.sh --task-invocation
```

**Expected Duration**: 4 hours (increased from 3 due to additional edge case detection)

### Phase 5: Documentation and Standards Updates [COMPLETE]
dependencies: [4]

**Objective**: Update all relevant documentation to reflect Task invocation requirements and edge case handling

**Complexity**: Low

**Tasks**:
- [x] Update hard-barrier-subagent-delegation.md with Task invocation pattern requirements (file: .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
  - Add section "Task Invocation Requirements"
  - Show pseudo-code anti-pattern vs imperative pattern
  - Add section "Edge Case Patterns": iteration loops, instructional text, conditional invocations
  - Reference supervise.md fix (commit 0b710aff) as canonical example
- [x] Update command-authoring.md Task Tool Invocation Patterns section (file: .claude/docs/reference/standards/command-authoring.md)
  - Explicitly forbid naked `Task {` blocks without imperative directives
  - Explicitly forbid instructional text patterns without actual Task invocations
  - Add to Prohibited Patterns section
  - Show correct template pattern
  - Document iteration loop and conditional invocation patterns
- [x] Update command-patterns-quick-reference.md with Task invocation template (file: .claude/docs/reference/command-patterns-quick-reference.md)
  - Add "Agent Delegation - Task Invocation" section
  - Provide copy-paste template for common agent types
  - Add templates for iteration loop invocations and conditional invocations
- [x] Update enforcement-mechanisms.md with task invocation linter details (file: .claude/docs/reference/standards/enforcement-mechanisms.md)
  - Add lint-task-invocation-pattern.sh to enforcement tools table
  - Document ERROR-level violations for naked Task blocks and instructional text patterns
- [x] Update CLAUDE.md code_standards section to reference Task invocation requirements (file: /home/benjamin/.config/CLAUDE.md)
  - Add note about imperative Task directives in Quick Reference
- [x] Create migration guide for converting legacy Task blocks (file: .claude/docs/guides/migration/task-invocation-pattern-migration.md)
  - Document before/after patterns for all command types
  - Provide step-by-step conversion instructions for pseudo-code, instructional text, and iteration loops
  - Reference this fix as case study with examples from all 7 fixed commands

**Testing**:
```bash
# Verify all documentation files updated
test -f .claude/docs/guides/migration/task-invocation-pattern-migration.md
grep -q "Task Invocation Requirements" .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
grep -q "Edge Case Patterns" .claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
grep -q "Prohibited.*Task {" .claude/docs/reference/standards/command-authoring.md
grep -q "iteration loop" .claude/docs/reference/standards/command-authoring.md

# Verify migration guide covers all patterns
grep -q "pseudo-code" .claude/docs/guides/migration/task-invocation-pattern-migration.md
grep -q "instructional text" .claude/docs/guides/migration/task-invocation-pattern-migration.md
grep -q "iteration loop" .claude/docs/guides/migration/task-invocation-pattern-migration.md

# Verify cross-references are valid
bash .claude/scripts/validate-links-quick.sh

# Verify README structure compliance
bash .claude/scripts/validate-readmes.sh
```

**Expected Duration**: 3 hours (increased from 2 due to edge case documentation)

### Phase 6: Fix Agent File Task Invocation Violations [COMPLETE]
dependencies: [4]

**Objective**: Apply imperative Task invocation pattern to all agent, template, and prompt files with naked Task blocks

**Complexity**: Medium (33 mechanical fixes)

**Tasks**:
- [x] Fix expand.md:938 - Complete incomplete EXECUTE NOW directive (file: .claude/commands/expand.md)
- [x] Fix optimize-claude.md:200 - Complete incomplete EXECUTE NOW directive (file: .claude/commands/optimize-claude.md)
- [x] Fix plan-architect.md: Add EXECUTE NOW to 3 Task blocks at lines 737, 782, 839 (file: .claude/agents/plan-architect.md)
- [x] Fix implementer-coordinator.md: Add EXECUTE NOW to 2 Task blocks at lines 267, 297 (file: .claude/agents/implementer-coordinator.md)
- [x] Fix research-specialist.md: Add EXECUTE NOW to 3 Task blocks at lines 564, 605, 628 (file: .claude/agents/research-specialist.md)
- [x] Fix spec-updater.md: Add EXECUTE NOW to 5 Task blocks at lines 418, 468, 750, 788, 824 (file: .claude/agents/spec-updater.md)
- [x] Fix debug-specialist.md: Add EXECUTE NOW to 4 Task blocks at lines 386, 423, 459, 670 (file: .claude/agents/debug-specialist.md)
- [x] Fix implementation-executor.md: Add EXECUTE NOW to 1 Task block at line 344 (file: .claude/agents/implementation-executor.md)
- [x] Fix research-sub-supervisor.md: Add EXECUTE NOW to 4 Task blocks at lines 137, 156, 175, 194 (file: .claude/agents/research-sub-supervisor.md)
- [x] Fix conversion-coordinator.md: Add EXECUTE NOW to 2 Task blocks at lines 85, 105 (file: .claude/agents/conversion-coordinator.md)
- [x] Fix doc-converter.md: Add EXECUTE NOW to 1 Task block at line 773 (file: .claude/agents/doc-converter.md)
- [x] Fix sub-supervisor-template.md: Add EXECUTE NOW to 4 Task blocks at lines 144, 164, 184, 204 (file: .claude/agents/templates/sub-supervisor-template.md)
- [x] Fix evaluate-phase-expansion.md: Add EXECUTE NOW to 1 Task block at line 92 (file: .claude/agents/prompts/evaluate-phase-expansion.md)
- [x] Fix evaluate-phase-collapse.md: Add EXECUTE NOW to 1 Task block at line 101 (file: .claude/agents/prompts/evaluate-phase-collapse.md)
- [x] Run linter to verify all 33 violations fixed: bash .claude/scripts/lint-task-invocation-pattern.sh
- [x] Run full validation: bash .claude/scripts/validate-all-standards.sh --task-invocation

**Testing**:
```bash
# Verify all violations fixed
bash .claude/scripts/lint-task-invocation-pattern.sh
# Expected: 0 ERROR violations

# Run full standards validation
bash .claude/scripts/validate-all-standards.sh --all

# Verify pattern consistency across all files
find .claude/agents .claude/commands -name "*.md" -type f | while read file; do
  if grep -q "^Task {" "$file"; then
    if ! grep -B2 "^Task {" "$file" | grep -q "EXECUTE NOW.*Task tool"; then
      echo "VIOLATION: $file"
    fi
  fi
done
# Expected: No output

# Test workflow commands still delegate correctly (no regressions)
# Manual verification that agent examples don't affect actual delegation behavior
```

**Expected Duration**: 3-4 hours

## Testing Strategy

### Unit Testing
- Linter test suite validates detection of incorrect Task patterns
- Validator test suite confirms hard barrier compliance checks
- Pattern matching tests verify regex accuracy

### Integration Testing
- Manual testing of each fixed command to verify delegation occurs
- Verify agents are invoked (check for agent behavioral file reads)
- Confirm artifacts created at expected paths (not inline generation)
- Test with --dry-run flags where available

### Regression Testing
- Run full command test suite after each phase
- Verify no functional regressions in command behavior
- Check that error handling still works correctly

### Validation Testing
- Run validate-all-standards.sh with --all flag
- Confirm 100% compliance on hard barrier validation
- Test pre-commit hook blocks bad Task invocations

## Documentation Requirements

### New Documentation
- Migration guide for Task invocation pattern (.claude/docs/guides/migration/task-invocation-pattern-migration.md)
- Linter script with inline documentation (.claude/scripts/lint-task-invocation-pattern.sh)
- Test suite for linter (.claude/tests/validators/test_lint_task_invocation.sh)
- Audit report documenting current state (.claude/specs/006_plan_command_orchestration_fix/reports/002-audit-report.md)

### Updated Documentation
- Hard barrier delegation pattern (.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- Command authoring standards (.claude/docs/reference/standards/command-authoring.md)
- Command patterns quick reference (.claude/docs/reference/command-patterns-quick-reference.md)
- Enforcement mechanisms reference (.claude/docs/reference/standards/enforcement-mechanisms.md)
- CLAUDE.md code_standards section (/home/benjamin/.config/CLAUDE.md)

### Documentation Standards
- All updates follow existing documentation format
- Cross-references use relative paths
- Examples show both anti-pattern and correct pattern
- Migration guide includes step-by-step instructions

## Dependencies

### External Dependencies
- Git commit 0b710aff (supervise.md fix) serves as canonical example
- Existing validation scripts (validate-hard-barrier-compliance.sh, validate-all-standards.sh)
- Pre-commit hook infrastructure

### Internal Dependencies
- Hard barrier delegation pattern documentation
- Command authoring standards
- Error handling pattern
- State persistence library

### Phase Dependencies
- Phase 2 depends on Phase 1 (audit must complete first)
- Phase 3 depends on Phase 2 (validate pattern on high-priority commands)
- Phase 4 depends on Phase 3 (all commands fixed before creating enforcement)
- Phase 5 depends on Phase 4 (document validated pattern)

## Risk Assessment

### High Risk
- **Breaking existing commands**: Changing Task invocation syntax could break delegation if pattern incorrect
  - Mitigation: Test each command manually after fix, use supervise.md as reference
- **Incomplete coverage**: Missing some commands with pseudo-code Task blocks
  - Mitigation: Comprehensive grep audit in Phase 1, validator in Phase 4

### Medium Risk
- **False positives in linter**: Detecting Task blocks in documentation/examples as violations
  - Mitigation: Exempt README.md and docs/ directories, test on known-good files
- **Behavioral changes**: Commands may behave differently after enforcing delegation
  - Mitigation: Extensive testing, document any changes observed

### Low Risk
- **Documentation inconsistency**: Updated docs contradict other documentation
  - Mitigation: Cross-reference validation, review all related docs
- **Performance impact**: Additional validation in pre-commit hook
  - Mitigation: Linter is fast grep-based script, < 1 second overhead

## Rollback Plan

If critical issues discovered after implementation:

1. **Immediate Rollback**: Use git to revert all command file changes
   ```bash
   git checkout HEAD~1 .claude/commands/*.md
   ```

2. **Disable Enforcement**: Comment out lint-task-invocation-pattern.sh in pre-commit hook

3. **Preserve Documentation**: Keep updated docs as they document the INTENDED pattern

4. **Re-analyze**: Review failures, update fix approach, re-test before second attempt

## Success Metrics

- 100% of commands and agents pass `bash .claude/scripts/validate-hard-barrier-compliance.sh`
- 0 commands or agents with naked `Task {` blocks without imperative directives
- 0 commands with instructional text patterns without actual Task invocations
- All 7 workflow commands (build, debug, implement, plan, repair, research, revise, test) properly delegate to agents
- All 16+ Task invocations fixed across all commands
- All 33 agent file Task invocation violations fixed
- Template files corrected to prevent propagation of incorrect patterns
- Agent example sections consistently demonstrate correct invocation syntax
- Edge cases handled: iteration loops (/implement), instructional text (/test), conditional invocations (/build)
- Pre-commit hook blocks future violations (naked Task blocks AND instructional text patterns)
- Documentation comprehensively covers correct Task invocation pattern including edge cases
- Zero functional regressions in existing command behavior

## Notes

This fix addresses a critical architectural flaw where orchestrator commands bypass agent delegation due to pseudo-code syntax that Claude doesn't recognize as tool calls. The imperative pattern from commit 0b710aff (supervise.md fix) is the canonical reference and has been validated to work correctly.

**System-Wide Impact**: Initial analysis identified /plan as the only affected command, but cross-command research revealed ALL 7 workflow commands suffer from the same issue. This plan has been revised to reflect the expanded scope.

The fix is urgent because:
1. Current behavior wastes 40-60% more context tokens in ALL orchestrators (not just /plan)
2. Defeats architectural purpose of agent specialization across entire command suite
3. Makes testing and reusability impossible for all workflow commands
4. Creates unpredictable command behavior system-wide
5. Affects every major workflow: build, debug, implement, plan, repair, research, revise, test

The phased approach ensures safe, tested rollout with validation at each step. Phase 2 prioritizes commands by usage and complexity, with /build and /debug (4 Task invocations each) taking precedence.

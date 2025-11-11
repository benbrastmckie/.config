# Implementation Plan: Fix Coordinate Agent Invocation and Bash Variable Error

## Plan Metadata
- **Plan ID**: 637-001
- **Status**: pending
- **Created**: 2025-11-10
- **Complexity Score**: 12 (refactor base=5 + 8 tasks/2=4 + 1 file*3=3)
- **Estimated Duration**: 2-3 hours
- **Plan Tier**: 1 (inline phases, low-medium complexity)
- **Dependencies**: None

## Context

The /coordinate command has two critical issues revealed during execution:

1. **Incorrect Agent Invocation Pattern**: The planning phase (lines 672-688) incorrectly invokes `/plan` as a slash command using Task tool, rather than directly invoking the plan-architect agent with behavioral injection. This violates Standard 11 (Imperative Agent Invocation Pattern) and breaks orchestrator-executor separation.

2. **Bash Variable Indirection Error**: workflow-initialization.sh line 319 uses `${!var_name}` indirect expansion which triggers history expansion errors when accessing `REPORT_PATH_N` variables, causing "unbound variable" errors (exit code 127).

## Research Reports Referenced

This plan is guided by comprehensive research:

1. **001_coordinate_command_structure.md** - Confirms /coordinate uses Task tool (not SlashCommand) but planning phase embeds /plan execution instead of invoking plan-architect agent directly
2. **002_bash_variable_error.md** - Identifies indirect expansion conflict with history expansion, recommends defensive checks and alternative patterns
3. **003_agent_invocation_patterns.md** - Documents Standard 11 requirements, provides corrected code patterns for all phases, recommends creating missing agent files if needed
4. **004_output_error_analysis.md** - Confirms parallel agent execution worked correctly despite errors, but bash variable error needs fixing

## Success Criteria

- [ ] Planning phase invokes plan-architect agent (not /plan command)
- [ ] Behavioral injection pattern follows Standard 11 requirements
- [ ] Bash variable indirection error resolved
- [ ] All tests pass (coordinate command integration tests)
- [ ] Documentation updated to clarify correct patterns

## Implementation Phases

### Phase 1: Fix Coordinate Planning Phase Agent Invocation

**Objective**: Replace /plan slash command invocation with plan-architect agent behavioral injection

**Current Issues**:
- Lines 672-688 of coordinate.md invoke `/plan` as slash command
- Violates Standard 11 (no direct agent behavioral file reference)
- Breaks orchestrator-executor separation pattern
- Cannot inject pre-calculated PLAN_PATH (path control lost)

**Tasks**:
1. Open `/home/benjamin/.config/.claude/commands/coordinate.md`
2. Locate planning phase invocation (lines 672-688)
3. Replace with correct behavioral injection pattern:
   - Add imperative instruction prefix: `**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent`
   - Reference agent behavioral file: `/home/benjamin/.config/.claude/agents/plan-architect.md`
   - Inject workflow-specific context (WORKFLOW_DESCRIPTION, PLAN_PATH, REPORT_PATHS, CLAUDE.md path)
   - Remove "Execute the /plan slash command" language
   - Ensure PLAN_PATH is pre-calculated in Phase 0 (verify or add if missing)
   - Update completion signal: `Return: PLAN_CREATED: $PLAN_PATH`
4. Verify PLAN_PATH pre-calculation exists in Phase 0 (earlier in coordinate.md)
5. If PLAN_PATH not pre-calculated, add to Phase 0 initialization using `create_topic_artifact`

**Correct Pattern Template** (from research report 003):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: $WORKFLOW_DESCRIPTION
    - Plan Output Path: $PLAN_PATH (absolute, pre-calculated)
    - Research Reports: [list of $REPORT_PATHS]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Topic Directory: $TOPIC_PATH

    **Key Requirements**:
    1. Review research findings in provided reports
    2. Create implementation plan following project standards
    3. Save plan to EXACT path provided above
    4. Include phase dependencies for parallel execution

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: $PLAN_PATH
  "
}
```

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 672-688)

**Testing**:
- Invoke `/coordinate "test feature"` and verify plan-architect agent is called
- Verify plan created at pre-calculated path
- Verify no "Execute the /plan slash command" in agent prompt

**Acceptance Criteria**:
- [ ] Planning phase references `.claude/agents/plan-architect.md`
- [ ] Imperative instruction prefix present
- [ ] PLAN_PATH pre-calculated and injected
- [ ] Completion signal follows standard format
- [ ] No slash command language in Task prompt

### Phase 2: Fix Bash Variable Indirection Error

**Objective**: Replace unsafe indirect expansion with defensive pattern that handles missing variables

**Current Issues**:
- Line 319 uses `${!var_name}` which triggers history expansion errors
- No existence check before accessing variables
- Comment is misleading (says indirect expansion avoids unbound variable error, but actually causes it)

**Tasks**:
1. Open `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
2. Locate `reconstruct_report_paths_array()` function (lines 313-321)
3. Add defensive existence check before variable access:
   ```bash
   reconstruct_report_paths_array() {
     REPORT_PATHS=()
     for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
       local var_name="REPORT_PATH_$i"

       # Defensive check: verify variable exists before accessing
       if [ -z "${!var_name+x}" ]; then
         echo "WARNING: $var_name not set, skipping" >&2
         continue
       fi

       # Safe to use indirect expansion now
       REPORT_PATHS+=("${!var_name}")
     done
   }
   ```
4. Update comment to accurately describe the pattern:
   ```bash
   # Use indirect expansion with defensive existence check
   # ${!var_name+x} returns "x" if variable exists, empty if undefined
   # This prevents "unbound variable" errors when variables not loaded from state
   ```
5. Verify calling code loads state before reconstruction (check coordinate.md usage)

**Alternative Considered** (from research report 002):
- JSON-based array persistence (already used in coordinate.md line 660)
- This alternative is already implemented, so focus on defensive checks for backward compatibility

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (lines 313-321)

**Testing**:
- Run coordinate command and verify no "unbound variable" errors
- Test with missing REPORT_PATH_N variables (simulate error condition)
- Verify graceful degradation with warning message

**Acceptance Criteria**:
- [ ] Existence check added before indirect expansion
- [ ] Warning message for missing variables
- [ ] Comment accurately describes pattern
- [ ] No exit code 127 errors during coordinate execution
- [ ] Backward compatibility maintained

### Phase 3: Update Documentation

**Objective**: Document correct agent invocation patterns and coordinate architecture

**Tasks**:
1. Update `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (create if doesn't exist)
2. Add section explaining planning phase behavioral injection pattern:
   - Why Task tool is used (not SlashCommand)
   - Behavioral injection pattern benefits
   - Path pre-calculation requirements
   - Agent behavioral file references
   - Comparison with anti-pattern (command-to-command invocation)
3. Add architectural note explaining planning phase design:
   ```markdown
   ## Architectural Note: Planning Phase Design

   The planning phase uses behavioral injection to invoke the plan-architect agent
   rather than the /plan slash command. This design choice:

   1. Maintains orchestrator-executor separation (Standard 0 Phase 0)
   2. Enables path pre-calculation for artifact control
   3. Follows Standard 11 (Imperative Agent Invocation Pattern)
   4. Prevents context bloat from nested command prompts
   5. Enables metadata extraction for 95% context reduction

   The plan-architect agent receives:
   - Pre-calculated PLAN_PATH from orchestrator
   - Research report paths as context
   - Complete behavioral guidelines from .claude/agents/plan-architect.md
   - Workflow-specific requirements injection
   ```
4. Update bash variable error documentation in coordinate state management docs
5. Cross-reference Standard 11 and behavioral injection pattern documentation

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (create or update)
- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (add error handling section)

**Testing**:
- Review documentation for clarity and accuracy
- Verify cross-references are correct
- Ensure examples match implemented patterns

**Acceptance Criteria**:
- [ ] Coordinate command guide created/updated with planning phase pattern
- [ ] Architectural note explains design rationale
- [ ] Bash error handling documented
- [ ] Cross-references to Standard 11 added
- [ ] Examples match actual implementation

### Phase 4: Validation and Testing

**Objective**: Ensure fixes work correctly and don't introduce regressions

**Tasks**:
1. Run validation script (if exists):
   ```bash
   /home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh /home/benjamin/.config/.claude/commands/coordinate.md
   ```
2. Run coordinate command integration tests:
   ```bash
   cd /home/benjamin/.config/.claude/tests
   ./test_orchestration_commands.sh coordinate
   ```
3. Perform end-to-end test of coordinate command:
   ```bash
   cd /home/benjamin/.config
   # Test complete workflow
   # Should create research reports, plan, and complete without errors
   ```
4. Verify specific fixes:
   - Check planning phase invokes plan-architect agent (grep for agent reference)
   - Check no "Execute the /plan slash command" in coordinate.md
   - Run coordinate and verify no bash variable errors in output
   - Verify all artifacts created at expected paths
   - Check delegation rate >90% (agent invocations succeed)
5. Review error output for any remaining issues

**Expected Results**:
- Validation script: PASS (0 violations)
- Integration tests: All tests pass
- End-to-end test: Complete workflow without errors
- Delegation rate: >90%
- File creation rate: 100%
- No bash exit code 127 errors

**Testing Commands**:
```bash
# Validation
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md

# Pattern verification
grep -n "Execute the /plan" .claude/commands/coordinate.md  # Should return 0 results
grep -n "plan-architect.md" .claude/commands/coordinate.md  # Should find behavioral file reference

# Integration test
cd .claude/tests && ./test_orchestration_commands.sh coordinate

# End-to-end test (minimal workflow)
cd /home/benjamin/.config
# (Test command would be here - coordinate creates real artifacts)
```

**Files Modified**:
- None (testing phase only)

**Acceptance Criteria**:
- [ ] Validation script passes (0 violations)
- [ ] Integration tests pass
- [ ] No bash variable errors in output
- [ ] Plan-architect agent invoked correctly
- [ ] All artifacts created at expected paths
- [ ] Documentation reviewed and accurate

## Risk Assessment

**High Risk**:
- None identified (changes are localized and well-understood)

**Medium Risk**:
- Changing coordinate.md planning phase might affect existing workflows
  - Mitigation: Research shows parallel invocation already works, only fixing invocation pattern
- Bash variable pattern change might affect other library users
  - Mitigation: Adding defensive check maintains backward compatibility

**Low Risk**:
- Documentation updates
  - Mitigation: No functional changes

## Dependencies Between Phases

```
Phase 1 (Fix agent invocation)
  ↓
Phase 2 (Fix bash variable error)  ← Independent of Phase 1
  ↓
Phase 3 (Update documentation)     ← Depends on Phase 1 & 2 completion
  ↓
Phase 4 (Validation and testing)   ← Depends on all previous phases
```

**Parallelization Opportunity**: Phase 1 and Phase 2 are independent and can be executed in parallel.

## Rollback Plan

If issues arise:
1. **Phase 1 Rollback**: Restore original /plan invocation pattern from git
2. **Phase 2 Rollback**: Remove defensive check, restore original indirect expansion
3. **Phase 3 Rollback**: Revert documentation changes
4. **Phase 4 Rollback**: No rollback needed (testing only)

**Git Commands**:
```bash
# Rollback coordinate.md changes
git checkout HEAD -- .claude/commands/coordinate.md

# Rollback workflow-initialization.sh changes
git checkout HEAD -- .claude/lib/workflow-initialization.sh

# Rollback documentation changes
git checkout HEAD -- .claude/docs/guides/coordinate-command-guide.md
```

## Technical Notes

### Standard 11 Compliance Requirements

From research report 003, Standard 11 requires:

1. **Imperative instruction**: `**EXECUTE NOW**: USE the Task tool...`
2. **Agent behavioral file reference**: `Read and follow: .claude/agents/plan-architect.md`
3. **No code block wrappers**: Task invocation NOT fenced with markdown code blocks
4. **No "Example" prefixes**: Remove documentation context
5. **Completion signal requirement**: `Return: PLAN_CREATED: [absolute-path]`
6. **No undermining disclaimers**: Clean imperative without contradictions

### Bash Subprocess Isolation Pattern

From research report 004:
- Each bash block runs in separate subprocess
- Errors in bash blocks don't affect Task tool invocations
- Task tool runs at orchestration level (not in bash subprocess)
- Parallel Task calls happen independently of bash state
- This explains why parallel invocation worked despite bash errors

### Path Pre-Calculation Pattern

From research report 003 (Standard 0 Phase 0):
- Orchestrators MUST pre-calculate all artifact paths before invoking agents
- Agents receive paths as injected context
- Prevents agents from calculating paths independently
- Enables orchestrator control over file locations
- Required for metadata extraction pattern

## Implementation Notes

**Critical Success Factors**:
1. Planning phase must reference plan-architect agent behavioral file
2. Bash variable check must handle missing variables gracefully
3. Documentation must clarify orchestrator-executor separation

**Code Review Checklist**:
- [ ] Imperative instruction precedes Task invocation
- [ ] Agent behavioral file referenced in prompt
- [ ] Path pre-calculated and injected
- [ ] Completion signal follows standard format
- [ ] Bash variable existence check added
- [ ] Comments accurately describe patterns
- [ ] Documentation cross-references correct

**Performance Considerations**:
- Defensive check adds minimal overhead (one variable existence test per array element)
- Agent invocation pattern change has no performance impact (same Task tool used)
- Documentation changes have zero runtime impact

## References

### Research Reports
- `/home/benjamin/.config/.claude/specs/637_coordinate_outputmd_which_has_errors_and_reveals/reports/001_coordinate_command_structure.md`
- `/home/benjamin/.config/.claude/specs/637_coordinate_outputmd_which_has_errors_and_reveals/reports/002_bash_variable_error.md`
- `/home/benjamin/.config/.claude/specs/637_coordinate_outputmd_which_has_errors_and_reveals/reports/003_agent_invocation_patterns.md`
- `/home/benjamin/.config/.claude/specs/637_coordinate_outputmd_which_has_errors_and_reveals/reports/004_output_error_analysis.md`

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Standard 11, lines 1173-1353)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (Behavioral injection pattern)

### Agent Files
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (Target agent for planning phase)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (Reference pattern for imperative language)

### Library Files
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (Contains error at line 319)
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh` (Path pre-calculation utilities)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (State loading for variables)

### Test Files
- `/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh` (Pattern validation)
- `/home/benjamin/.config/.claude/tests/test_orchestration_commands.sh` (Integration tests)

## Completion Verification

This plan is complete when:
1. ✅ All phase acceptance criteria met
2. ✅ Validation script passes (0 violations)
3. ✅ Integration tests pass
4. ✅ End-to-end coordinate workflow completes without errors
5. ✅ Documentation reviewed and accurate
6. ✅ No bash variable indirection errors in output
7. ✅ Planning phase invokes plan-architect agent (not /plan command)

**Final Validation Command**:
```bash
# Verify agent invocation pattern
grep -c "plan-architect.md" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: 1 (exactly one reference in planning phase)

grep -c "Execute the /plan" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: 0 (no slash command invocations)

# Run validation
/home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: PASS
```

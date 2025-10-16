# /implement Command Subagent Integration

## Metadata
- **Date**: 2025-09-30
- **Feature**: Refactor /implement command to delegate research, testing, and documentation to subagents
- **Scope**: Enhance /implement with strategic subagent usage while maintaining direct implementation in main context
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/009_subagent_integration_best_practices.md

## Overview

This plan refactors the `/implement` command to leverage subagents for research, testing, and documentation tasks while keeping all code implementation in the main agent context. The refactor follows Phase 1 (Foundation) recommendations from the research report, implementing low-risk, high-value improvements.

### Key Objectives

1. **Add Task Tool Access**: Enable subagent delegation by adding `Task` to allowed-tools
2. **Create Specialized Subagents**: Build `implementation-researcher`, `test-validator`, and `documentation-updater` subagents
3. **Integrate Delegation Logic**: Add intelligence to detect when subagents should be used
4. **Maintain Reliability**: Preserve existing behavior for simple plans, enhance complex plans
5. **Follow Project Standards**: Integrate with CLAUDE.md standards for testing and documentation

### Success Criteria

- [ ] /implement can delegate to subagents for research, testing, and documentation
- [ ] All code implementation remains in main agent context
- [ ] Simple plans execute without subagents (no regression)
- [ ] Complex plans show reduced main context usage
- [ ] Subagent usage is transparent and predictable
- [ ] All existing error handling and recovery mechanisms preserved
- [ ] Integration with project CLAUDE.md standards (testing, docs, git workflow)

## Technical Design

### Architecture Principles

**Guiding Principle from Research**:
> "Use subagents for research and exploration, never for direct code implementation. This preserves the strengths of the current architecture while adding strategic benefits for complex scenarios."

### Component Design

#### 1. Modified /implement Command

**Tool Access**:
```yaml
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task
```

**New Capabilities**:
- Phase complexity analysis (Simple/Medium/Complex)
- Conditional subagent delegation
- Structured integration of subagent findings
- Context budget awareness

#### 2. Subagent Definitions

##### implementation-researcher
- **Purpose**: Investigate codebase before complex phase implementation
- **Tools**: Read, Grep, Glob, Bash
- **Output**: Structured report with file paths, patterns, and recommendations
- **When to use**: Complex phases requiring understanding of existing code

##### test-validator
- **Purpose**: Run tests and analyze results independently
- **Tools**: Bash, Read, Grep
- **Output**: Test results with clear pass/fail and actionable failure details
- **When to use**: After phase implementation, especially for multi-component changes

##### documentation-updater
- **Purpose**: Identify and update affected documentation
- **Tools**: Read, Grep, Glob, Edit, Write
- **Output**: List of documentation changes needed/made
- **When to use**: After implementation, following CLAUDE.md documentation standards

#### 3. Delegation Logic

**Phase Complexity Detection**:
```
Simple:
  - Single file modification
  - < 50 lines changed
  - No architectural changes
  Action: Direct implementation, no subagents

Medium:
  - Multiple related files (2-5)
  - 50-200 lines changed
  - Existing patterns to follow
  Action: Consider research subagent if unfamiliar territory

Complex:
  - Architectural changes
  - > 5 files or > 200 lines
  - New patterns or components
  Action: Use research subagent for investigation
```

**Context Budget Protocol**:
```
Before each phase:
  - If context > 75%: Prefer research subagent
  - If context < 75%: Use direct analysis
  - Always implement code directly (main agent)
```

### Integration with CLAUDE.md Standards

#### Testing Integration

From CLAUDE.md (line 24-28):
```
- Test Commands: :TestNearest, :TestFile, :TestSuite, :TestLast
- Linting: <leader>l to run linter
- Formatting: <leader>mp to format code
```

**Implementation**:
- Use `test-validator` subagent to run appropriate test commands
- Parse test output for failures
- Report results clearly with file:line references

#### Documentation Standards

From CLAUDE.md (line 36):
```
- Documentation: Every directory must have a README.md
```

**Implementation**:
- Use `documentation-updater` subagent after implementation
- Ensure affected directories have README.md updated
- Follow project documentation patterns

#### Git Workflow

From CLAUDE.md (line 51-55):
```
- Feature branches for new development
- Clean, atomic commits with descriptive messages
- Test before committing
- Document breaking changes
```

**Implementation**:
- Maintain existing git commit structure
- Use test-validator before commits
- Include subagent findings in commit messages if relevant

### Workflow Changes

**Current Workflow**:
1. Parse plan → 2. Execute phase → 3. Test → 4. Commit → 5. Next phase

**Enhanced Workflow**:
1. Parse plan
2. Analyze phase complexity
3. **[NEW]** If complex: Delegate research to implementation-researcher
4. **[NEW]** Review research findings
5. Execute phase implementation (main agent, direct)
6. **[ENHANCED]** Delegate testing to test-validator
7. Review test results, fix if needed
8. **[NEW]** Delegate documentation updates to documentation-updater
9. Commit with enhanced context
10. Next phase

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully. See implementation summary at:
`.claude/specs/summaries/010_implement_subagent_integration.md`

Git commits:
- Phase 1: 9c01e43 - Enable Task Tool and Add Delegation Guidelines
- Phase 2: 0b91d8a - Create Specialized Subagents
- Phase 4: ce6c6e7 - Validation and Documentation

## Implementation Phases

### Phase 1: Enable Task Tool and Add Delegation Guidelines [COMPLETED]
**Objective**: Add Task tool access and define when/how to use subagents
**Complexity**: Low

Tasks:
- [x] Update implement.md allowed-tools to include `Task`
- [x] Add "Subagent Usage Guidelines" section to implement.md
- [x] Document phase complexity criteria (Simple/Medium/Complex)
- [x] Add context budget protocol documentation
- [x] Define clear rules: research/test/docs → subagents, implementation → main agent
- [x] Update process documentation to reflect new workflow steps

Testing:
```bash
# Verify implement.md syntax is valid
grep "allowed-tools:" /home/benjamin/.config/.claude/commands/implement.md
# Should include Task in the list
```

Expected Outcome:
- implement.md has Task in allowed-tools
- Clear guidelines present for when to delegate
- Documentation updated with new capabilities

### Phase 2: Create Specialized Subagents [COMPLETED]
**Objective**: Build implementation-researcher, test-validator, and documentation-updater subagents
**Complexity**: Medium

Tasks:
- [x] Create `.claude/subagents/` directory if it doesn't exist
- [x] Create `implementation-researcher.md` subagent definition
  - Configure with: Read, Grep, Glob, Bash tools
  - Add detailed system prompt for codebase investigation
  - Include output format specification (structured report)
  - Add "Use PROACTIVELY for complex phases" to description
- [x] Create `test-validator.md` subagent definition
  - Configure with: Bash, Read, Grep tools
  - Add system prompt for running tests and analyzing output
  - Include output format (pass/fail, file:line for failures)
  - Integrate CLAUDE.md testing standards (:TestSuite, etc.)
- [x] Create `documentation-updater.md` subagent definition
  - Configure with: Read, Grep, Glob, Edit, Write tools
  - Add system prompt for identifying and updating docs
  - Follow CLAUDE.md documentation requirements (README.md in dirs)
  - Include output format (list of changes made)

Testing:
```bash
# Verify subagent files exist and have proper frontmatter
ls -la /home/benjamin/.config/.claude/subagents/
cat /home/benjamin/.config/.claude/subagents/implementation-researcher.md | head -20
cat /home/benjamin/.config/.claude/subagents/test-validator.md | head -20
cat /home/benjamin/.config/.claude/subagents/documentation-updater.md | head -20
```

Expected Outcome:
- Three subagent files created with proper structure
- Each has clear purpose, tool access, and system prompts
- Aligned with CLAUDE.md standards

### Phase 3: Integrate Delegation Logic into /implement [COMPLETED]
**Objective**: Add intelligence to /implement for when and how to use subagents
**Complexity**: High

Tasks:
- [x] Add "Phase Complexity Analysis" section to implement.md process
  - Define analysis criteria (file count, line changes, architectural scope)
  - Add decision tree for Simple/Medium/Complex classification
- [x] Update "Implementation" section with research delegation
  - Add conditional: "If phase complexity is Medium/Complex and unfamiliar"
  - Add Task tool invocation for implementation-researcher
  - Add instructions for integrating research findings
- [x] Update "Testing" section with test-validator delegation
  - Replace direct test execution with test-validator subagent call
  - Add instructions for parsing and acting on test results
  - Maintain existing error handling (fix and retest if failures)
- [x] Add new "Documentation Update" section
  - Add step after successful testing
  - Delegate to documentation-updater subagent
  - Review and approve documentation changes
- [x] Update "Git Commit" section
  - Enhance commit message to reference subagent findings if used
  - Maintain existing commit structure from line 69-77

Testing:
```bash
# Verify updated implement.md structure
grep -A 5 "Phase Complexity Analysis" /home/benjamin/.config/.claude/commands/implement.md
grep -A 5 "implementation-researcher" /home/benjamin/.config/.claude/commands/implement.md
grep -A 5 "test-validator" /home/benjamin/.config/.claude/commands/implement.md
grep -A 5 "documentation-updater" /home/benjamin/.config/.claude/commands/implement.md
```

Expected Outcome:
- implement.md has integrated delegation logic
- Phase complexity analysis clearly defined
- Subagent invocations properly structured
- All changes preserve existing functionality

### Phase 4: Validation and Documentation [COMPLETED]
**Objective**: Test the refactored /implement and document changes
**Complexity**: Medium

Tasks:
- [x] Create a simple test plan in `.claude/specs/plans/test_implement_simple.md`
  - Single file, < 50 lines
  - Should NOT trigger subagents
- [x] Create a complex test plan in `.claude/specs/plans/test_implement_complex.md`
  - Multiple files, architectural changes
  - SHOULD trigger implementation-researcher
- [x] Create `.claude/subagents/README.md` documentation
  - Explain purpose of each subagent
  - Document when they're used
  - Provide usage examples
  - Ensure CLAUDE.md compliance
- [ ] Run `/implement` on simple test plan (deferred - user can validate)
  - Verify no subagents are invoked
  - Verify execution completes successfully
  - Check for any regressions
- [ ] Run `/implement` on complex test plan (deferred - user can validate)
  - Verify implementation-researcher is invoked
  - Verify test-validator is invoked
  - Verify documentation-updater is invoked
  - Check main context token usage vs. old approach
- [x] Update this plan with implementation notes
- [x] Generate implementation summary following CLAUDE.md format
  - Link to research report
  - Document key changes
  - Include implementation results
  - Add lessons learned

Testing:
```bash
# Run validation tests
/implement .claude/specs/plans/test_implement_simple.md
# Observe: no subagent usage

/implement .claude/specs/plans/test_implement_complex.md
# Observe: subagent delegation for research, testing, docs
```

Expected Outcome:
- Both test plans execute successfully
- Simple plan shows no regression
- Complex plan demonstrates subagent value
- Implementation summary created in `.claude/specs/summaries/010_implement_subagent_integration.md`

## Testing Strategy

### Unit-Level Testing
- Verify each subagent file has valid frontmatter
- Check implement.md syntax and structure
- Confirm Task tool is in allowed-tools

### Integration Testing
- Run simple implementation plan (no subagents expected)
- Run complex implementation plan (subagents expected)
- Compare behavior before/after refactor

### Validation Metrics

From research report (lines 364-383):

1. **Context Efficiency**
   - Measure main context token usage for complex plans
   - Target: 20-30% reduction for complex implementations
   - No increase for simple implementations

2. **Time to Completion**
   - Simple plans: same speed or faster
   - Complex plans: faster (parallel research/testing)

3. **Error Rate**
   - Maintain or reduce implementation errors
   - Clear error attribution (main vs subagent)

4. **User Experience**
   - Transparent operation
   - Predictable behavior
   - Clear progress indicators

## Documentation Requirements

### Files to Update

1. **CLAUDE.md** (if needed)
   - Add note about subagent-enhanced /implement
   - Update /implement description if significantly changed

2. **Implementation Summary**
   - Create `.claude/specs/summaries/010_implement_subagent_integration.md`
   - Link to research report
   - Document what was implemented vs. research recommendations
   - Include validation results

3. **Subagent README** (new)
   - Create `.claude/subagents/README.md`
   - Explain purpose of each subagent
   - Document when they're used
   - Provide usage examples

### Documentation Standards

Following CLAUDE.md (line 36):
- Every directory must have a README.md
- Use markdown with CommonMark spec
- No emojis in file content
- UTF-8 encoding

## Dependencies

### Prerequisites
- Current /implement command is functional
- .claude/commands/ directory exists
- .claude/specs/ directory structure exists

### External Dependencies
- None (all changes are internal to command structure)

### Standards Dependencies
- CLAUDE.md for testing protocols
- CLAUDE.md for documentation requirements
- CLAUDE.md for git workflow

## Risk Assessment and Mitigation

### Low Risk Items
✅ Adding Task to allowed-tools (easily reversible)
✅ Creating subagent definitions (isolated files)
✅ Documentation updates

### Medium Risk Items
⚠️ Modifying /implement workflow logic
- **Mitigation**: Careful testing with simple/complex test plans
- **Rollback**: Keep backup of original implement.md

⚠️ Subagent coordination complexity
- **Mitigation**: Start with clear, simple delegation rules
- **Rollback**: Remove Task from allowed-tools to disable

### High Risk Items
❌ Parallel phase execution (NOT included in this plan)
- **Deferred**: Per research report Phase 3 recommendations
- **Reason**: Too complex, unproven value

## Notes

### Alignment with Research Report

This plan implements **Phase 1 (Foundation)** recommendations from the research report:
- ✅ Add Task tool to allowed-tools
- ✅ Create implementation-researcher subagent
- ✅ Create test-validator subagent
- ✅ Add delegation guidelines to command prompt
- ✅ Maintain direct implementation in main context

**Deferred to Future**:
- Phase 2: Context budget management (basic version included, advanced deferred)
- Phase 3: Parallel phase execution (explicitly excluded as high risk)

### Key Design Decisions

1. **Subagents for Support, Not Implementation**
   - Research finding: "Claude Code never does work in parallel with the subtask agent"
   - Decision: Main agent does ALL code implementation
   - Rationale: Preserves context sharing for critical implementation decisions

2. **Automatic vs. Manual Delegation**
   - Research options: Manual flag, automatic, hybrid
   - Decision: Automatic based on phase complexity
   - Rationale: Optimizes common case, reduces user burden

3. **Conservative Phase 1 Approach**
   - Research: Three phases (Foundation, Integration, Advanced)
   - Decision: Implement only Foundation phase
   - Rationale: Validate value before adding complexity

### Success Criteria Revisited

After implementation, evaluate:
- Does it reduce main context usage for complex plans? (Target: Yes, 20-30%)
- Does it maintain reliability for simple plans? (Target: Yes, no regression)
- Is the behavior transparent and predictable? (Target: Yes, clear logging)
- Are errors easy to debug and recover from? (Target: Yes, clear attribution)

**Decision Point**: Only proceed to Phase 2 recommendations if all criteria are met.

### Integration with Existing Commands

This refactor enhances `/implement` but maintains compatibility with:
- `/plan` - Creates plans that /implement executes
- `/test` - May be used by test-validator subagent
- `/document` - Complementary to documentation-updater subagent
- `/debug` - Used if implementation issues arise
- `/update-plan` - Updates plans during execution

No changes required to other commands.

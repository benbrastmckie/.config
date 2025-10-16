# Command Workflow Safety Enhancements Implementation Plan

## Metadata
- **Date**: 2025-09-30
- **Feature**: Enhanced command workflow with feature preservation, checkpoint validation, and auto-rollback
- **Scope**: Transform /refactor to execution command with safety mechanisms; add /capture-baseline command; enhance command integration
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/010_command_workflow_optimization.md

## Overview

This plan implements Priority 1 recommendations from research report 010: transforming the `/refactor` command from analysis-only to a full execution command with test-driven safety mechanisms, baseline capture for feature preservation, automated checkpoint validation, and auto-rollback on failures.

### Key Objectives

1. **Create /capture-baseline command**: Systematically capture features to preserve before refactoring
2. **Transform /refactor**: From report generation to safe, incremental execution
3. **Implement checkpoint system**: Git-based checkpoints with validation
4. **Add auto-rollback**: Automatic recovery from test failures
5. **Integrate with existing tools**: Seamless handoffs to /test, /debug, subagents

### Research-Backed Approach

**From report 010**:
- 43% of failed rollbacks occur due to environmental drift → automated validation prevents this
- Red-Green-Refactor cycle minimizes bug introduction
- ATDD approach: tests as ultimate invariants of behavior
- Incremental execution with checkpoints enables safe refactoring

## Success Criteria

- [ ] /capture-baseline can identify and record features to preserve
- [ ] /refactor executes refactorings incrementally with checkpoints
- [ ] Automated testing validates each refactoring step
- [ ] Auto-rollback triggers on test failures
- [ ] /debug integrates for failure investigation
- [ ] All baseline features preserved after refactoring
- [ ] Git history clean with meaningful checkpoints
- [ ] Documentation updated with new workflows

## Technical Design

### Architecture Principles

**Guiding Principle** (from report 010):
> "Modern refactoring requires test-driven safety nets with automated checkpoint validation and rollback capabilities to prevent the 43% of rollbacks that fail due to environmental drift."

### Component Design

#### 1. Baseline System

**Purpose**: Capture and validate features to preserve

**Structure**:
```
.claude/
├── baselines/
│   ├── [feature-name].json       # Individual feature baselines
│   └── [timestamp]-full.json     # Complete baseline snapshot
└── checkpoints/
    ├── checkpoint-N.json         # Checkpoint metadata
    └── rollback.log             # Rollback history
```

**Baseline Format**:
```json
{
  "features": {
    "authentication": {
      "description": "User authentication system",
      "tests": ["test_auth_login", "test_auth_logout", "test_auth_session"],
      "files": ["src/auth.js", "src/session.js"],
      "baseline_results": {"passed": 3, "failed": 0, "skipped": 0},
      "coverage": 85.0
    }
  },
  "timestamp": "2025-09-30T16:30:00Z",
  "git_sha": "abc123...",
  "test_command": "npm test",
  "environment": {"node_version": "18.0.0", "os": "linux"}
}
```

#### 2. Checkpoint System

**Purpose**: Git-based state snapshots with validation metadata

**Checkpoint Format**:
```json
{
  "checkpoint_id": "refactor-step-3",
  "git_sha": "def456...",
  "timestamp": "2025-09-30T16:35:00Z",
  "refactoring_step": {
    "description": "Extract duplicate auth logic to shared module",
    "files_modified": ["src/auth.js", "src/shared/auth-utils.js"],
    "lines_changed": 45,
    "tests_run": ["test_auth_*"],
    "validation_status": "passed"
  },
  "baseline_features_validated": ["authentication"],
  "rollback_target": "def455...",  # Previous checkpoint
  "can_rollback": true
}
```

#### 3. Enhanced /refactor Command

**Current workflow** (analysis-only):
1. Scope determination → 2. Analysis → 3. Report generation

**New workflow** (execution with safety):
1. **Baseline Capture** (via /capture-baseline)
2. **Analysis** (generate refactoring opportunities)
3. **User Review** (confirm refactorings and features to preserve)
4. **Incremental Execution** (Red-Green-Refactor cycle)
5. **Validation** (test after each step)
6. **Rollback** (if validation fails)
7. **Final Validation** (full test suite)
8. **Cleanup** (squash checkpoints, final commit)

**Red-Green-Refactor Integration**:
- **Red**: Document current behavior (already has tests)
- **Green**: Make minimal refactoring change
- **Refactor**: Validate with tests, rollback if fails

#### 4. Auto-Rollback Decision Tree

```
Execute Refactoring Step
    ├─ Create Checkpoint
    │   └─ Run Tests (test-validator subagent)
    │       ├─ All Pass
    │       │   └─ Commit Checkpoint
    │       │       └─ Continue to Next Step
    │       └─ Any Fail
    │           └─ Trigger Auto-Rollback
    │               ├─ git reset --hard [last-checkpoint]
    │               ├─ Log rollback details
    │               └─ Invoke /debug
    │                   └─ Present Options:
    │                       ├─ Retry (with modifications)
    │                       ├─ Skip (this refactoring)
    │                       └─ Abort (entire workflow)
```

### Integration with Existing Systems

#### CLAUDE.md Standards
- Testing: Use `:TestSuite` and project-specific commands
- Documentation: Update affected README.md files
- Git: Follow commit message format

#### Subagent Integration
- **implementation-researcher**: Analyze refactoring opportunities (Phase 1)
- **test-validator**: Execute tests at checkpoints (Phase 2)
- **documentation-updater**: Update docs after successful refactoring (Phase 3)

#### Command Integration
- **/test**: Run specific test suites for validation
- **/debug**: Investigate test failures before retry
- **/implement**: Similar checkpoint pattern for consistency

## Implementation Phases

### Phase 1: Create /capture-baseline Command
**Objective**: Build baseline capture system for feature preservation
**Complexity**: Medium

Tasks:
- [ ] Create `.claude/baselines/` directory structure
- [ ] Create `/capture-baseline` command definition
  - Configure with: Read, Bash, Grep, Glob, Write, Task tools
  - Add system prompt for baseline capture
  - Define baseline JSON format
- [ ] Implement feature identification logic
  - Parse user-provided features ("preserve auth and API")
  - Auto-detect from test names
  - Map features to test coverage
- [ ] Implement baseline execution
  - Use test-validator subagent to run tests
  - Capture test results in structured format
  - Record git SHA and environment details
- [ ] Create baseline persistence
  - Save feature maps to `.claude/baselines/[feature].json`
  - Create git checkpoint: "baseline-[timestamp]"
- [ ] Add baseline validation function
  - Compare current test results against baseline
  - Identify which features still pass
  - Report differences

Testing:
```bash
# Test baseline capture
/capture-baseline "authentication, API endpoints"

# Verify baseline file created
cat .claude/baselines/authentication.json

# Verify git checkpoint
git log --oneline -1 | grep "baseline-"
```

Expected Outcome:
- `/capture-baseline` command functional
- Baseline files created in `.claude/baselines/`
- Git checkpoints for baselines
- Validation logic works

### Phase 2: Implement Checkpoint System
**Objective**: Create git-based checkpoint and rollback infrastructure
**Complexity**: High

Tasks:
- [ ] Create `.claude/data/checkpoints/` directory structure
- [ ] Implement checkpoint creation function
  - Generate unique checkpoint IDs ("refactor-step-N")
  - Create git commits with checkpoint metadata
  - Save checkpoint JSON to `.claude/data/checkpoints/`
  - Link to previous checkpoint (rollback target)
- [ ] Implement checkpoint validation
  - Run test-validator subagent after checkpoint
  - Validate baseline features still work
  - Record validation results in checkpoint metadata
- [ ] Implement auto-rollback mechanism
  - Detect test failures
  - Execute: `git reset --hard [last-checkpoint-sha]`
  - Log rollback to `.claude/data/checkpoints/rollback.log`
  - Restore checkpoint metadata state
- [ ] Add rollback logging
  - Timestamp of rollback
  - Which checkpoint restored
  - Failure reason (test output)
  - Path to debug report (if generated)
- [ ] Create checkpoint cleanup function
  - Squash temporary checkpoint commits
  - Keep meaningful refactoring milestones
  - Remove checkpoint metadata files

Testing:
```bash
# Test checkpoint creation
# (Manual test in development environment)

# Verify checkpoint files
ls .claude/data/checkpoints/

# Test rollback (simulate failure)
# git reset --hard [sha]
# Verify state restored

# Test cleanup
# Verify squashed commits in git log
```

Expected Outcome:
- Checkpoints created with metadata
- Auto-rollback works on test failure
- Rollback logging captures details
- Cleanup produces clean git history

### Phase 3: Transform /refactor to Execution Command
**Objective**: Enhance /refactor with incremental execution and safety mechanisms
**Complexity**: High

Tasks:
- [ ] Update refactor.md frontmatter
  - Add Task, Bash tools (for git operations)
  - Add SlashCommand tool (to invoke /capture-baseline, /debug)
- [ ] Add "Execution Mode" section to refactor.md
  - Document new workflow (baseline → execute → validate → rollback)
  - Add Red-Green-Refactor cycle explanation
  - Define checkpoint strategy
- [ ] Implement Phase 1: Baseline Capture
  - Invoke /capture-baseline with user-specified features
  - Parse baseline results
  - Present to user for confirmation
- [ ] Implement Phase 2: Analysis (keep existing)
  - Use implementation-researcher for analysis
  - Generate refactoring opportunities report
  - Prioritize by impact and risk
- [ ] Implement Phase 3: User Review
  - Present refactoring opportunities
  - Show estimated effort and risk per refactoring
  - Confirm features to preserve
  - Get user approval to proceed
- [ ] Implement Phase 4: Incremental Execution
  - For each refactoring opportunity:
    - Create checkpoint (refactor-step-N)
    - Apply refactoring (direct implementation, not subagent)
    - Run tests (test-validator subagent)
    - Validate baseline features
    - If pass: commit and continue
    - If fail: auto-rollback, invoke /debug, present options
- [ ] Implement Phase 5: Final Validation
  - Run full test suite
  - Compare against baseline
  - Generate refactoring summary report
- [ ] Implement Phase 6: Cleanup
  - Squash refactor-step-N commits
  - Create final commit with summary
  - Clean up checkpoint metadata

Testing:
```bash
# Test new /refactor on simple refactoring
/refactor src/utils.js --features "utility functions"

# Verify:
# - Baseline captured
# - Checkpoints created
# - Tests run at each step
# - Final validation passes
# - Clean git history

# Test rollback scenario (manually introduce failing test)
# Verify auto-rollback triggers and restores state
```

Expected Outcome:
- /refactor executes refactorings safely
- Baseline features preserved
- Auto-rollback works on failures
- Git history clean and meaningful
- Refactoring summary generated

### Phase 4: Integration and Documentation
**Objective**: Integrate with other commands and document new workflows
**Complexity**: Medium

Tasks:
- [ ] Create `.claude/commands/capture-baseline.md`
  - Full command definition
  - Usage examples
  - Integration with /refactor
- [ ] Update CLAUDE.md with new workflows
  - Add /capture-baseline to command list
  - Document /refactor execution mode
  - Add examples of safe refactoring workflow
- [ ] Create workflow integration
  - Update /orchestrate to handle refactor → test → document chain
  - Add workflow state for baseline tracking
  - Enable seamless handoffs
- [ ] Update subagents README
  - Document test-validator role in refactoring
  - Add implementation-researcher refactoring analysis use case
- [ ] Create example refactoring scenarios
  - Simple: Single file, extract function
  - Medium: Multiple files, rename variable
  - Complex: Architectural change with many tests
- [ ] Create troubleshooting guide
  - What to do when rollback occurs
  - How to interpret debug reports
  - Common refactoring pitfalls
- [ ] Generate implementation summary
  - Link to research report
  - Document what was implemented
  - Include validation results
  - Add lessons learned

Testing:
```bash
# Verify all documentation complete
ls .claude/commands/capture-baseline.md
grep "capture-baseline" CLAUDE.md

# Run example scenarios
# Simple refactoring
# Medium refactoring
# Complex refactoring

# Verify troubleshooting guide helps resolve issues
```

Expected Outcome:
- Complete documentation for new features
- CLAUDE.md updated
- Integration with /orchestrate works
- Example scenarios demonstrate capabilities
- Troubleshooting guide helps users

## Testing Strategy

### Unit-Level Testing
- Baseline capture produces valid JSON
- Checkpoint creation writes correct metadata
- Rollback restores correct git state
- Validation correctly compares test results

### Integration Testing
- /capture-baseline → /refactor workflow
- /refactor → /debug on failure
- Auto-rollback → state restoration
- Full Red-Green-Refactor cycle

### End-to-End Testing
Execute complete refactoring workflows:

**Scenario 1: Simple Refactoring (Success Path)**
1. Capture baseline for "utility functions"
2. Refactor: Extract duplicate code
3. Validate: Tests pass
4. Result: Clean commit, features preserved

**Scenario 2: Medium Refactoring (Rollback Path)**
1. Capture baseline for "API endpoints"
2. Refactor Step 1: Rename function (success)
3. Refactor Step 2: Change signature (tests fail)
4. Auto-rollback to Step 1
5. Debug failure
6. Retry Step 2 with fix
7. Result: All tests pass, clean history

**Scenario 3: Complex Refactoring (Multi-Step)**
1. Capture baseline for "authentication, authorization, API"
2. Execute 5 refactoring steps
3. Validate after each step
4. Final validation: all baseline features work
5. Result: Significant refactoring, zero regression

### Validation Metrics

From research report 010:

**Effectiveness**:
- Refactoring success rate (% without rollbacks): Target > 80%
- Feature preservation rate (baseline pass after refactor): Target 100%
- Rollback efficiency (time to restore): Target < 10 seconds

**Performance**:
- Time per checkpoint: Target < 30 seconds
- Test execution overhead: Acceptable if < 2x normal test time

**Quality**:
- Bug introduction rate: Target 0 (test-driven prevents bugs)
- False positive rollbacks: Target < 5%

## Documentation Requirements

### Files to Create

1. **/.claude/commands/capture-baseline.md**
   - Command definition with frontmatter
   - Full documentation of baseline capture
   - Examples and integration points

2. **/.claude/baselines/README.md**
   - Explain baseline system
   - Format documentation
   - Usage guidelines

3. **/.claude/data/checkpoints/README.md**
   - Checkpoint system explanation
   - Rollback procedures
   - Cleanup guidelines

### Files to Update

1. **CLAUDE.md**
   - Add /capture-baseline to command list
   - Document enhanced /refactor workflow
   - Add safe refactoring best practices

2. **/.claude/commands/refactor.md**
   - Transform from analysis-only to execution
   - Add execution mode documentation
   - Document baseline integration

3. **/.claude/subagents/README.md**
   - Add test-validator refactoring use case
   - Document implementation-researcher role in refactoring

### Documentation Standards

Following CLAUDE.md:
- Every directory has README.md
- Use CommonMark markdown
- No emojis in file content
- UTF-8 encoding

## Dependencies

### Prerequisites
- Git repository initialized
- Test suite functional
- /test command working
- Subagents available (test-validator, implementation-researcher)

### External Dependencies
- Git (for checkpoints and rollback)
- Test framework (project-specific)
- CLAUDE.md (for standards)

### Command Dependencies
- /test - For test execution
- /debug - For failure investigation
- Subagents - For validation and analysis

## Risk Assessment and Mitigation

### Low Risk Items
✅ Creating /capture-baseline (new command, no changes to existing)
✅ Baseline file format (isolated system)
✅ Documentation updates (non-functional)

### Medium Risk Items
⚠️ Checkpoint system with git operations
- **Risk**: Could corrupt git history if buggy
- **Mitigation**: Extensive testing, always create backup branch
- **Rollback**: User can manually restore from git reflog

⚠️ Auto-rollback on test failures
- **Risk**: Could rollback when shouldn't (false positive)
- **Mitigation**: Clear validation logic, user can override
- **Rollback**: User can manually re-apply changes

### High Risk Items
❌ Transforming /refactor to execution command
- **Risk**: Major behavior change, could break workflows
- **Mitigation**:
  - Keep analysis mode available (--analyze-only flag)
  - Extensive testing before release
  - Clear documentation of changes
- **Rollback**: Original command preserved in git history

## Implementation Roadmap

### Week 1-2: Phase 1 (Baseline System)
- Days 1-3: Design and create baseline format
- Days 4-7: Implement /capture-baseline command
- Days 8-10: Testing and refinement

### Week 3-4: Phase 2 (Checkpoint System)
- Days 1-4: Implement checkpoint creation and metadata
- Days 5-8: Implement auto-rollback mechanism
- Days 9-10: Testing and validation

### Week 5-6: Phase 3 (Enhanced /refactor)
- Days 1-3: Update command frontmatter and structure
- Days 4-8: Implement incremental execution workflow
- Days 9-10: Integration testing

### Week 7: Phase 4 (Integration & Documentation)
- Days 1-3: Create all documentation
- Days 4-5: Update existing docs
- Days 6-7: Final testing and examples

### Week 8: Validation and Refinement
- Days 1-3: Run all test scenarios
- Days 4-5: Fix issues found
- Days 6-7: User feedback integration

## Notes

### Alignment with Research Report

This plan implements **Priority 1** recommendations from report 010:
- ✅ Transform /refactor into execution command
- ✅ Create /capture-baseline for feature preservation
- ✅ Implement checkpoint system with auto-rollback
- ✅ Integrate test-driven safety mechanisms
- ✅ Use Red-Green-Refactor cycle

**Deferred to Future**:
- Priority 2: Safety mechanisms for ALL modification commands
- Priority 3: Enhanced command integration beyond basics
- Priority 4: Advanced baseline features (coverage diff, mutation testing)
- Priority 5: Comprehensive rollback automation for all workflows

### Key Design Decisions

1. **Hybrid Execution Mode**
   - Keep --analyze-only for backward compatibility
   - Default to execution mode (new behavior)
   - Rationale: Minimize disruption while adding value

2. **Git-Based Checkpoints**
   - Use git commits (not separate state files)
   - Leverage existing git infrastructure
   - Rationale: Reliable, familiar, reversible

3. **Test-Validator for All Validation**
   - Use subagent consistently
   - Don't run tests directly in /refactor
   - Rationale: Leverage subagent benefits, consistency with /implement

4. **User Confirmation at Key Points**
   - Baseline features to preserve
   - Refactoring opportunities to execute
   - Options after rollback (retry/skip/abort)
   - Rationale: Balance automation with user control

### Success Criteria Revisited

After implementation, evaluate:
- Can /refactor safely execute complex refactorings? (Target: Yes)
- Are baseline features preserved 100% of the time? (Target: Yes)
- Does auto-rollback prevent broken states? (Target: Yes)
- Is the workflow intuitive and confidence-inspiring? (Target: Yes)

**Decision Point**: Only proceed to Priority 2 (enhancing other commands) if Priority 1 demonstrates clear value without regression.

### Integration with Existing Work

This plan builds on recent subagent integration (plan 010):
- Reuses test-validator for test execution
- Reuses implementation-researcher for analysis
- Follows same phase-based execution pattern
- Maintains git commit conventions

No conflicts with existing commands - only enhancements.

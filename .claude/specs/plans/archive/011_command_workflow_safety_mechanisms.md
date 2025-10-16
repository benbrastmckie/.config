# Command Workflow Safety Mechanisms Implementation Plan

## Metadata
- **Date**: 2025-09-30
- **Feature**: Command workflow safety mechanisms with feature preservation, checkpoints, and rollback
- **Scope**: Phase 1 implementation - Core safety mechanisms for /refactor command
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `.claude/specs/reports/010_command_workflow_optimization.md`
  - `.claude/specs/reports/009_subagent_integration_best_practices.md`

## Overview

Transform the `/refactor` command from an analysis-only tool into a full execution command with comprehensive safety mechanisms. This implementation focuses on Phase 1 from the research report: baseline capture, checkpoint validation, and automated rollback capabilities.

### Key Goals

1. **Feature Preservation**: Capture and validate baseline functionality throughout refactoring
2. **Incremental Safety**: Git-based checkpoints with automated rollback on test failures
3. **Test-Driven Workflow**: Red-Green-Refactor cycle with validation at each step
4. **Seamless Integration**: Leverage existing subagents (test-validator, implementation-researcher)

### Research Insights

From report 010:
- 43% of failed rollbacks occur due to environmental drift → automated validation prevents this
- Modern refactoring requires ATDD (Acceptance Test-Driven Development) approach
- Red-Green-Refactor cycle minimizes bug introduction risk
- Commands should interoperate seamlessly with shared state

## Success Criteria

- [ ] `/refactor` can execute refactorings with safety mechanisms (not just analyze)
- [ ] Baseline features are captured before refactoring begins
- [ ] Checkpoints are created before each refactoring step
- [ ] Tests run automatically after each change
- [ ] Auto-rollback occurs on test failures
- [ ] User has control with --interactive and --analyze-only modes
- [ ] Integration with /test and /debug commands works seamlessly
- [ ] All 27 commands remain functional (no breaking changes)

## Technical Design

### Architecture Overview

```
.claude/
├── commands/
│   ├── refactor.md (enhanced with execution mode)
│   └── capture-baseline.md (new command)
├── baselines/
│   └── [feature-name]-[timestamp].json (feature maps)
├── checkpoints/
│   ├── refactor-[timestamp]/
│   │   ├── checkpoint-N.json (checkpoint metadata)
│   │   └── rollback.log (rollback history)
│   └── current-refactor.json (active refactoring state)
└── specs/
    ├── plans/
    └── reports/
```

### Key Components

#### 1. Baseline System
- **Feature map structure**: JSON format linking features → tests → files
- **Capture mechanism**: Run tests, record results, create git checkpoint
- **Storage**: `.claude/baselines/[name]-[timestamp].json`

#### 2. Checkpoint System
- **Git-based**: Each checkpoint is a git commit with special prefix
- **Metadata tracking**: JSON files tracking checkpoint state
- **Rollback mechanism**: `git reset --hard [checkpoint-sha]`

#### 3. Validation System
- **Test execution**: Via test-validator subagent
- **Result comparison**: Baseline vs. current test results
- **Failure detection**: Any test that passed baseline but fails now

#### 4. Enhanced /refactor Command
- **Modes**: `--auto`, `--interactive`, `--analyze-only`
- **Phases**: Baseline → Analysis → Incremental Refactoring → Final Validation → Cleanup
- **Integration**: Uses test-validator, implementation-researcher subagents

### Data Structures

#### Baseline Feature Map
```json
{
  "timestamp": "2025-09-30T16:30:00Z",
  "git_sha": "abc123...",
  "features": {
    "authentication": {
      "description": "User login, logout, session management",
      "tests": [
        "test_auth_login",
        "test_auth_logout",
        "test_session_validation"
      ],
      "files": [
        "src/auth.js",
        "src/session.js"
      ],
      "baseline_results": {
        "total": 3,
        "passed": 3,
        "failed": 0,
        "test_output": "..."
      }
    }
  },
  "total_tests_run": 15,
  "all_passed": true
}
```

#### Checkpoint Metadata
```json
{
  "checkpoint_id": "refactor-step-3",
  "timestamp": "2025-09-30T16:35:00Z",
  "git_sha": "def456...",
  "parent_checkpoint": "refactor-step-2",
  "refactoring_step": {
    "number": 3,
    "description": "Extract duplicate auth logic into helper",
    "files_modified": ["src/auth.js"],
    "category": "code_duplication",
    "priority": "high"
  },
  "validation": {
    "tests_run": ["test_auth_*"],
    "result": "passed",
    "duration_ms": 1250
  },
  "can_rollback_to": "refactor-step-2"
}
```

#### Active Refactoring State
```json
{
  "refactoring_id": "refactor-20250930-163000",
  "start_time": "2025-09-30T16:30:00Z",
  "scope": "src/auth/ and src/session/",
  "baseline_path": ".claude/baselines/auth-session-20250930.json",
  "mode": "auto",
  "current_step": 3,
  "total_steps": 8,
  "checkpoints": [
    {"id": "baseline", "sha": "abc123"},
    {"id": "refactor-step-1", "sha": "def456"},
    {"id": "refactor-step-2", "sha": "ghi789"},
    {"id": "refactor-step-3", "sha": "jkl012"}
  ],
  "features_to_preserve": ["authentication", "session_management"],
  "rollback_count": 0
}
```

## Implementation Phases

### Phase 1: Baseline Capture System

**Objective**: Create infrastructure for capturing and validating baseline functionality
**Complexity**: Medium
**Estimated Time**: 2-3 hours

#### Tasks

- [ ] Create `.claude/baselines/` directory structure
- [ ] Design and implement baseline feature map JSON schema
- [ ] Create `/capture-baseline` command file at `.claude/commands/capture-baseline.md`
- [ ] Implement baseline capture logic:
  - [ ] Parse feature descriptions from user input
  - [ ] Discover relevant tests (via grep/glob for test files)
  - [ ] Execute test suite via test-validator subagent
  - [ ] Map features → tests → files
  - [ ] Record test results with timestamps
- [ ] Create git checkpoint with baseline tag
- [ ] Save feature map to `.claude/baselines/[name]-[timestamp].json`
- [ ] Add error handling for test failures during baseline capture

#### Testing

```bash
# Test baseline capture
/capture-baseline "authentication, session management"

# Verify baseline file created
ls -la .claude/baselines/

# Verify feature map structure
cat .claude/baselines/auth-session-*.json | jq .
```

**Expected outcomes**:
- Baseline file created with valid JSON structure
- All features mapped to tests
- Git checkpoint created with tag
- Test results recorded accurately

### Phase 2: Checkpoint and Rollback System

**Objective**: Implement git-based checkpoints with automated rollback capability
**Complexity**: High
**Estimated Time**: 4-5 hours

#### Tasks

- [ ] Create `.claude/data/checkpoints/` directory structure
- [ ] Implement checkpoint creation logic:
  - [ ] Generate unique checkpoint ID
  - [ ] Create git commit with prefix `refactor-checkpoint-N:`
  - [ ] Save checkpoint metadata JSON
  - [ ] Link to parent checkpoint
  - [ ] Update active refactoring state
- [ ] Implement rollback mechanism:
  - [ ] Detect test failures after checkpoint
  - [ ] Read last successful checkpoint from state
  - [ ] Execute `git reset --hard [checkpoint-sha]`
  - [ ] Log rollback to `.claude/data/checkpoints/rollback.log`
  - [ ] Update active refactoring state
  - [ ] Clean up checkpoint metadata for rolled-back step
- [ ] Add checkpoint cleanup logic (remove temporary commits after success)
- [ ] Implement state persistence across command invocations
- [ ] Add rollback history tracking

#### Testing

```bash
# Test checkpoint creation
git log --oneline | grep "refactor-checkpoint"

# Verify checkpoint metadata
cat .claude/data/checkpoints/refactor-*/checkpoint-*.json | jq .

# Test rollback (simulate failure)
# 1. Create checkpoint
# 2. Make breaking change
# 3. Verify auto-rollback occurs
# 4. Check rollback.log

# Test state persistence
cat .claude/data/checkpoints/current-refactor.json | jq .
```

**Expected outcomes**:
- Git checkpoints created with correct format
- Checkpoint metadata saved and linkable
- Rollback successfully restores previous state
- Rollback log contains accurate history
- State persists between command invocations

### Phase 3: Enhanced /refactor Command Execution Mode

**Objective**: Transform /refactor from analysis-only to execution with safety mechanisms
**Complexity**: High
**Estimated Time**: 5-6 hours

#### Tasks

- [ ] Read current `/refactor` command at `.claude/commands/refactor.md`
- [ ] Add execution mode section to refactor.md:
  - [ ] Document three modes: `--auto`, `--interactive`, `--analyze-only`
  - [ ] Explain Red-Green-Refactor workflow
  - [ ] Document safety mechanisms
- [ ] Implement mode detection and routing:
  - [ ] Parse command arguments for mode flags
  - [ ] Default to `--analyze-only` for backward compatibility
  - [ ] Route to appropriate workflow
- [ ] Implement execution workflow:
  - [ ] **Step 1: Baseline Capture**
    - [ ] Prompt user for features to preserve
    - [ ] Call `/capture-baseline` command
    - [ ] Verify baseline creation
  - [ ] **Step 2: Analysis Phase** (existing behavior)
    - [ ] Use implementation-researcher subagent
    - [ ] Generate refactoring opportunities report
    - [ ] Present to user with priorities
  - [ ] **Step 3: User Approval**
    - [ ] Show opportunities with risk/effort estimates
    - [ ] Confirm features to preserve
    - [ ] Get explicit approval to proceed (unless --auto mode)
  - [ ] **Step 4: Incremental Refactoring**
    - [ ] For each opportunity (sorted by priority):
      - [ ] Create pre-change checkpoint
      - [ ] Display current refactoring step
      - [ ] Make code changes (direct implementation, no subagent delegation)
      - [ ] Create post-change checkpoint
      - [ ] Run test-validator subagent for affected tests
      - [ ] If tests pass: commit and continue
      - [ ] If tests fail: auto-rollback, invoke /debug, present options
  - [ ] **Step 5: Final Validation**
    - [ ] Run full test suite
    - [ ] Compare with baseline results
    - [ ] Report any discrepancies
  - [ ] **Step 6: Cleanup**
    - [ ] Squash temporary checkpoints into single commit
    - [ ] Generate refactoring summary
    - [ ] Clean up checkpoint metadata
- [ ] Add interactive mode prompts:
  - [ ] Confirm before each refactoring step
  - [ ] Show diff before applying
  - [ ] Allow skip/abort options
- [ ] Integrate with /debug on failures:
  - [ ] Pass failure context to /debug
  - [ ] Present debug report to user
  - [ ] Offer retry with modifications

#### Testing

```bash
# Test analyze-only mode (backward compatibility)
/refactor src/auth/ --analyze-only

# Test interactive mode
/refactor src/auth/ --interactive

# Simulate failure scenario
# 1. Run refactor with intentional breaking change
# 2. Verify auto-rollback triggers
# 3. Verify /debug is invoked
# 4. Check user options presented

# Test full auto mode
/refactor src/auth/ --auto

# Verify final state
git log --oneline | head -10
ls -la .claude/data/checkpoints/
ls -la .claude/baselines/
```

**Expected outcomes**:
- All three modes work correctly
- Backward compatibility maintained (default to analyze-only)
- Baseline capture happens automatically
- Checkpoints created at each step
- Auto-rollback triggers on test failures
- /debug integration works
- Final commit is clean (checkpoints squashed)
- Summary report generated

### Phase 4: Integration and Documentation

**Objective**: Ensure seamless integration with existing commands and comprehensive documentation
**Complexity**: Medium
**Estimated Time**: 2-3 hours

#### Tasks

- [ ] Update `/test` command integration:
  - [ ] Ensure /refactor can invoke /test for validation
  - [ ] Pass feature-specific test filters
  - [ ] Handle test results correctly
- [ ] Update `/debug` command integration:
  - [ ] Ensure /debug receives failure context from /refactor
  - [ ] Test diagnostic report generation
- [ ] Verify subagent integration:
  - [ ] test-validator subagent works for test execution
  - [ ] implementation-researcher subagent works for analysis
  - [ ] Subagents preserve context correctly
- [ ] Update CLAUDE.md documentation:
  - [ ] Add /capture-baseline command description
  - [ ] Update /refactor command documentation
  - [ ] Document safety mechanisms
  - [ ] Add examples of usage
- [ ] Create user-facing documentation:
  - [ ] Add examples to refactor.md
  - [ ] Document mode flags and their behavior
  - [ ] Explain checkpoint and rollback system
  - [ ] Provide troubleshooting guidance
- [ ] Test integration with /orchestrate:
  - [ ] Verify /orchestrate can chain /refactor → /test → /document
  - [ ] Test workflow state persistence
- [ ] Validate backward compatibility:
  - [ ] Ensure all 27 existing commands still work
  - [ ] No breaking changes to existing workflows
  - [ ] Default behavior unchanged (analyze-only)

#### Testing

```bash
# Test command chain
/refactor src/auth/ --auto && /test src/auth/ && /document

# Test via /orchestrate
/orchestrate "Refactor authentication module preserving all login features"

# Verify all existing commands still work
/list-plans
/list-reports
/implement [existing-plan]

# Check documentation
cat CLAUDE.md | grep -A 10 "refactor"
cat .claude/commands/refactor.md | head -50
```

**Expected outcomes**:
- /test integration works seamlessly
- /debug receives proper context
- Subagents function correctly
- CLAUDE.md updated with new commands
- Documentation is clear and comprehensive
- /orchestrate can chain commands
- All existing commands remain functional
- No breaking changes introduced

## Testing Strategy

### Unit-Level Testing

For each component (baseline, checkpoint, rollback):
1. Test JSON schema validation
2. Test file creation and persistence
3. Test error handling (missing files, invalid data)
4. Test edge cases (empty baselines, no tests found)

### Integration Testing

Test command interactions:
1. /capture-baseline → /refactor workflow
2. /refactor → /test integration
3. /refactor → /debug on failures
4. /orchestrate → /refactor chaining

### End-to-End Testing

Complete refactoring scenarios:
1. **Happy path**: Refactoring with all tests passing
2. **Rollback scenario**: Refactoring with test failure and auto-rollback
3. **Interactive mode**: User confirms each step
4. **Large refactoring**: Multiple steps, multiple checkpoints

### Regression Testing

Ensure existing functionality preserved:
1. Run all 27 commands and verify they work
2. Test existing plans with /implement
3. Verify /orchestrate workflows still function
4. Check CLAUDE.md compliance

## Risk Assessment and Mitigation

### High Risk Items

**Risk 1: Git state corruption during rollback**
- **Impact**: Loss of work, inconsistent repository state
- **Mitigation**:
  - Always verify git status before rollback
  - Create backup branch before starting refactoring
  - Log all git operations for audit trail
  - Add `--dry-run` flag for testing

**Risk 2: Test failures unrelated to refactoring**
- **Impact**: False positives triggering unnecessary rollbacks
- **Mitigation**:
  - Baseline capture ensures tests pass before starting
  - Compare baseline results vs. current results
  - Only rollback if previously passing tests now fail
  - Allow user override in interactive mode

**Risk 3: Breaking existing workflows**
- **Impact**: Users unable to use existing commands
- **Mitigation**:
  - Default to analyze-only mode (backward compatible)
  - Extensive testing of all 27 commands
  - Document migration path
  - Provide rollback instructions

### Medium Risk Items

**Risk 4: Subagent context preservation**
- **Impact**: Loss of refactoring context, incorrect analysis
- **Mitigation**:
  - Follow patterns from report 009 (subagent best practices)
  - Pass explicit context in subagent prompts
  - Test subagent integration thoroughly

**Risk 5: Checkpoint accumulation**
- **Impact**: Many temporary commits cluttering history
- **Mitigation**:
  - Implement checkpoint cleanup after success
  - Squash checkpoints into single final commit
  - Add manual cleanup command if needed

### Low Risk Items

**Risk 6: JSON schema evolution**
- **Impact**: Incompatibility with old baseline/checkpoint files
- **Mitigation**:
  - Version JSON schemas
  - Add migration logic if schema changes
  - Document schema format

## Dependencies

### External Dependencies
- Git (for checkpoints and rollback)
- Test framework (project-specific, discovered via CLAUDE.md)
- jq (for JSON manipulation in examples)

### Internal Dependencies
- test-validator subagent (from report 009)
- implementation-researcher subagent (from report 009)
- /test command (for test execution)
- /debug command (for failure diagnosis)
- TodoWrite tool (for progress tracking)

### Standards Dependencies
- CLAUDE.md (testing protocols, standards)
- Git workflow conventions (commit messages, branching)

## Rollback Plan

If implementation encounters critical issues:

### Phase 1 Rollback
- Delete `.claude/baselines/` directory
- Remove `/capture-baseline` command file
- Restore from git: `git checkout HEAD~N .claude/commands/`

### Phase 2 Rollback
- Delete `.claude/data/checkpoints/` directory
- No git changes made yet (checkpoint logic not active)

### Phase 3 Rollback
- Restore original refactor.md: `git checkout HEAD~N .claude/commands/refactor.md`
- Verify analyze-only mode still works
- Clean up any partial checkpoints

### Phase 4 Rollback
- Restore CLAUDE.md: `git checkout HEAD~N CLAUDE.md`
- Restore documentation changes

## Post-Implementation Tasks

After successful implementation:

1. **User Testing**
   - Beta test with real refactoring scenarios
   - Gather feedback on UX (modes, prompts, error messages)
   - Iterate based on feedback

2. **Performance Optimization**
   - Profile checkpoint creation time
   - Optimize test execution (parallel, selective)
   - Minimize git operations

3. **Documentation Enhancement**
   - Create video walkthrough
   - Add troubleshooting FAQ
   - Document common patterns

4. **Future Enhancements** (Phase 2+)
   - Add safety mechanisms to other commands (/implement, /debug)
   - Enhance /orchestrate with checkpoint management
   - Implement workflow state sharing (report 010 Priority 3)
   - Add `/baseline-diff` command to compare baselines

## Notes

### Design Decisions

**Why git-based checkpoints?**
- Leverages existing version control
- Users already understand git commits
- Easy to inspect history
- Built-in rollback via reset
- No custom VCS implementation needed

**Why three modes (auto, interactive, analyze-only)?**
- analyze-only: Backward compatibility
- interactive: User control for safety
- auto: Convenience for trusted scenarios
- Provides flexibility for different use cases

**Why separate /capture-baseline command?**
- Reusable for other commands (future enhancement)
- Testable in isolation
- Clear separation of concerns
- Can be invoked manually by user

### Implementation Order Rationale

Phase 1 → Phase 2 → Phase 3 → Phase 4 ensures:
- Foundation first (baseline, checkpoints)
- Core functionality second (execution mode)
- Polish last (integration, docs)
- Each phase builds on previous
- Can stop after any phase with partial functionality

### Alternative Approaches Considered

**Alternative 1: Custom checkpoint format (not git-based)**
- Rejected: More complexity, reinventing the wheel
- Git provides battle-tested VCS functionality

**Alternative 2: Single mode (always execute)**
- Rejected: Breaking change, no backward compatibility
- Users may want analysis without execution

**Alternative 3: Manual checkpoint creation**
- Rejected: Error-prone, inconsistent
- Automated checkpoints ensure safety

## Success Metrics

After implementation, measure:

### Effectiveness
- **Refactoring Success Rate**: % completed without manual rollbacks
- **Feature Preservation Rate**: % of baseline tests still passing
- **Rollback Efficiency**: Time from failure to restored state
- Target: >95% success rate, 100% feature preservation, <10s rollback

### Performance
- **Checkpoint Overhead**: Time to create checkpoint
- **Test Execution Time**: Time for validation
- Target: <5s checkpoint, <30s tests (project-dependent)

### Quality
- **Bug Introduction Rate**: Bugs introduced per refactoring
- **False Positive Rollbacks**: Rollbacks due to flaky tests
- Target: <0.1 bugs per refactoring, <5% false positive rate

### Usability
- **User Satisfaction**: Feedback from beta testers
- **Documentation Clarity**: Questions per user
- Target: >4/5 satisfaction, <2 questions per user

## Timeline Estimate

- **Phase 1**: 2-3 hours (baseline system)
- **Phase 2**: 4-5 hours (checkpoints and rollback)
- **Phase 3**: 5-6 hours (enhanced /refactor)
- **Phase 4**: 2-3 hours (integration and docs)

**Total**: 13-17 hours

**Recommended Approach**:
- Implement over 3-4 sessions
- Session 1: Phase 1 + Phase 2 start
- Session 2: Phase 2 complete + Phase 3 start
- Session 3: Phase 3 complete + Phase 4
- Session 4: Testing, refinement, documentation polish

## Ready for Implementation

This plan is ready for execution via `/implement`. The phases are:
- Well-defined with clear objectives
- Testable at each step
- Risk-assessed with mitigation strategies
- Backward-compatible with existing workflows
- Based on comprehensive research (report 010)

To begin implementation:
```bash
/implement .claude/specs/plans/011_command_workflow_safety_mechanisms.md
```

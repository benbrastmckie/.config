# Systematic Refactor Plan: Modernizing /setup and /optimize-claude Commands

## Metadata
- **Date**: 2025-11-20
- **Feature**: Command modernization for /setup and /optimize-claude
- **Scope**: Full standards compliance integration (error logging, bash block consolidation, documentation enhancement)
- **Estimated Phases**: 4 phases (all required)
- **Estimated Hours**: 15-19 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 167.5
- **Research Reports**:
  - [Setup and Optimize-Claude Analysis](/home/benjamin/.config/.claude/specs/843_optimizeclaude_commands_in_order_to_create_a_plan/reports/001_setup_optimize_claude_analysis.md)
  - [Systematic Refactor Plan](/home/benjamin/.config/.claude/specs/845_standards_to_modernize_setup_and_optimizeclaude/reports/001_setup_optimize_refactor_plan.md)

## Overview

This implementation plan provides a systematic, phased approach to modernizing the `/setup` (311 lines) and `/optimize-claude` (329 lines) commands to achieve full compliance with current .claude/docs/ standards. The refactor addresses four critical areas: (1) error logging integration for queryable error tracking via centralized error log, (2) bash block consolidation for 50-67% output noise reduction, (3) comprehensive guide file enhancement following executable/documentation separation pattern, and (4) enhancement features for improved usability. All four phases are required for complete modernization.

## Research Summary

Based on comprehensive analysis from research reports:

**Gap Analysis Findings**:
- Neither command integrates centralized error logging (Standard 17 violation)
- Both commands exceed 2-3 bash block target: /setup has 6 blocks, /optimize-claude has 8 blocks (Pattern 8 violation)
- /setup uses outdated SlashCommand pattern for agent invocation (Pattern 9 non-compliance)
- Both commands lack comprehensive verification checkpoints after file operations (Pattern 10 partial compliance)

**Reference Architecture**: The /plan command (426 lines, 3 blocks) demonstrates target architecture with full error logging integration, consolidated bash blocks, and behavioral injection pattern for agent invocation.

**Recommended Approach**: Four-phase implementation with clear rollback points: (1) Error logging integration, (2) Bash block consolidation, (3) Documentation and consistency improvements, (4) Enhancement features for improved usability. All four phases are required for complete modernization.

## Success Criteria

- [ ] Error logging: 100% of error exit points integrate `log_command_error()`
- [ ] Bash block reduction: /setup 6→4 blocks (33%), /optimize-claude 8→3 blocks (63%)
- [ ] Agent integration: /setup Phase 6 uses Task tool with behavioral injection
- [ ] Guide completeness: 90%+ coverage with expanded troubleshooting sections
- [ ] Test coverage: 80%+ line coverage with integration tests
- [ ] Error queryability: All errors accessible via `/errors --command`
- [ ] No regressions: All existing functionality preserved
- [ ] Standards compliance: 100% compliance with applicable .claude/docs/ standards

## Technical Design

### Architecture Overview

Both commands will adopt the three-block architecture pattern from /plan command:

**Block 1: Setup** - Consolidated initialization
- Project detection
- Library sourcing (error-handling.sh, domain-specific libraries)
- Error logging initialization (ensure_error_log_exists, workflow metadata)
- Argument parsing
- Validation with error logging
- Path allocation

**Block 2: Execute** - Mode-specific or agent-based operations
- /setup: Mode-specific execution (6 modes with guards)
- /optimize-claude: Agent execution with inline verification
- Inline verification checkpoints (fail-fast pattern)
- Error logging at all failure points

**Block 3: Cleanup** - Results display and completion
- Mode/workflow-specific completion messages
- Results summary
- Workflow completion signal

### Error Logging Integration Pattern

```bash
# Initialization (Block 1)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
ensure_error_log_exists
COMMAND_NAME="/command"
WORKFLOW_ID="command_$(date +%s)"
USER_ARGS="$*"

# Error logging at exit points (Throughout)
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "$error_type" \
  "$error_message" \
  "$source" \
  "$context_json"
```

### Bash Block Consolidation Strategy

**/setup** (6→4 blocks):
- Merge Phase 0 (arg parsing) + error logging init → Block 1 (Setup)
- Keep Phases 1-6 as Block 2 (Execute) with mode guards
- Split Phase 6 (enhancement) → Block 3 (Enhancement)
- Add new Block 4 (Cleanup)

**/optimize-claude** (8→3 blocks):
- Merge Phase 1 (path allocation) + error logging init → Block 1 (Setup)
- Merge Phases 3, 5, 7 (verifications) into inline verification → Block 2 (Execute)
- Keep Phase 8 → Block 3 (Cleanup)

### Agent Integration Standardization

/setup Phase 6 will migrate from SlashCommand to Task tool with behavioral injection:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Enhance CLAUDE.md with documentation analysis"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md

    [Workflow context and requirements]

    Return completion signal: WORKFLOW_COMPLETE
  "
}

# Parse completion signal
if echo "$output" | grep -q "WORKFLOW_COMPLETE"; then
  echo "✓ Enhancement complete"
else
  log_command_error [...] "agent_error" "Orchestration workflow failed"
  exit 1
fi
```

## Implementation Phases

### Phase 1: Error Logging Integration [COMPLETE]
dependencies: []

**Objective**: Integrate centralized error logging to enable queryable error tracking and post-mortem debugging for both commands.

**Complexity**: High

**Tasks**:

#### /setup Command Error Logging (2-3 hours)
- [x] Add error-handling.sh library sourcing after Phase 0 argument parsing (file: .claude/commands/setup.md, after line 27)
- [x] Initialize error log with `ensure_error_log_exists` and set workflow metadata (COMMAND_NAME="/setup", WORKFLOW_ID, USER_ARGS)
- [x] Update validation error at line 49-51 (apply-report validation) to call `log_command_error()` before exit
- [x] Update validation error at line 52-54 (report file not found) to call `log_command_error()` before exit
- [x] Update validation error at line 55-57 (dry-run validation) to call `log_command_error()` before exit
- [x] Add verification checkpoint after CLAUDE.md generation (Phase 1, after line 127) with file existence check and error logging
- [x] Add verification checkpoint after CLAUDE.md size validation with error logging for empty/invalid files
- [x] Add verification checkpoint after cleanup execution (Phase 2, after line 162) with error logging for script failures
- [x] Add verification checkpoint after analysis report creation (Phase 4, after line 247) with error logging
- [x] Create test suite `.claude/tests/test_setup_error_logging.sh` to verify error logging integration
- [x] Test error queryability via `/errors --command /setup` for all error types (validation_error, file_error, execution_error)

#### /optimize-claude Command Error Logging (2-3 hours)
- [x] Add error-handling.sh library sourcing in Phase 1 (file: .claude/commands/optimize-claude.md, after line 29)
- [x] Initialize error log with `ensure_error_log_exists` and set workflow metadata (COMMAND_NAME="/optimize-claude", WORKFLOW_ID, USER_ARGS)
- [x] Update path validation error (line 46) to call `log_command_error()` for topic path allocation failure
- [x] Update CLAUDE.md not found error (line 61) to call `log_command_error()` with file_error type
- [x] Update .claude/docs/ not found error (line 62) to call `log_command_error()` with file_error type
- [x] Replace research verification checkpoint (Phase 3, lines 124-145) with error logging for both agent failures (claude-md-analyzer, docs-structure-analyzer)
- [x] Replace analysis verification checkpoint (Phase 5, lines 212-233) with error logging for both agent failures (docs-bloat-analyzer, docs-accuracy-analyzer)
- [x] Replace plan verification checkpoint (Phase 7, lines 281-293) with error logging for agent failure (cleanup-plan-architect)
- [x] Create test suite `.claude/tests/test_optimize_claude_error_logging.sh` to verify error logging integration
- [x] Test error queryability via `/errors --command /optimize-claude` for all error types (state_error, file_error, agent_error)

**Testing**:
```bash
# Validation error logging
/setup --apply-report 2>&1 || true
/errors --command /setup --type validation_error --limit 1 | grep "Missing report path"

# File error logging
/setup --apply-report /nonexistent/report.md 2>&1 || true
/errors --command /setup --type file_error --limit 1 | grep "Report file not found"

# Agent error logging (optimize-claude)
# Mock agent failure scenario
/errors --command /optimize-claude --type agent_error --limit 1
```

**Expected Duration**: 4-6 hours (2-3 hours per command)

---

### Phase 2: Bash Block Consolidation [COMPLETE]
dependencies: [1]

**Objective**: Reduce bash block count to 2-3 blocks per command following Pattern 8 (Block Count Minimization) for cleaner output and faster execution.

**Complexity**: Medium

**Tasks**:

#### /setup Command Block Consolidation (1-1.5 hours)
- [x] Create Block 1 (Setup): Merge Phase 0 (arg parsing) + error logging init into single consolidated setup block (file: .claude/commands/setup.md)
- [x] Move project detection logic to Block 1
- [x] Move library sourcing (error-handling.sh) to Block 1 with `2>/dev/null` suppression
- [x] Move error logging initialization to Block 1
- [x] Move argument parsing loop to Block 1
- [x] Move validation checks to Block 1 with error logging
- [x] Add single summary line at end of Block 1: "Setup complete: Mode=$MODE | Project=$PROJECT_DIR | Workflow=$WORKFLOW_ID"
- [x] Keep Block 2 (Execute): Preserve Phases 1-5 with mode guards (if MODE != X, skip)
- [x] Create Block 3 (Enhancement): Extract Phase 6 to separate block for agent-based enhancement
- [x] Create Block 4 (Cleanup): Add new completion block with mode-specific messages
- [x] Verify block count reduction: 6 blocks → 4 blocks (33% reduction)
- [x] Test all 6 modes to verify functionality preserved after consolidation

#### /optimize-claude Command Block Consolidation (1-1.5 hours)
- [x] Create Block 1 (Setup): Merge Phase 1 (path allocation) + library sourcing + error logging init (file: .claude/commands/optimize-claude.md)
- [x] Move project detection to Block 1
- [x] Move unified-location-detection.sh sourcing to Block 1 with `2>/dev/null`
- [x] Move error-handling.sh sourcing to Block 1
- [x] Move error logging initialization to Block 1
- [x] Move path allocation logic to Block 1
- [x] Move CLAUDE.md and .claude/docs/ validation to Block 1 with error logging
- [x] Add single summary line at end of Block 1
- [x] Merge verification checkpoints into Block 2 (Execute): Create inline verification function `verify_reports()` called after each agent stage
- [x] Replace separate verification bash blocks (Phase 3, 5, 7) with inline verification after agent returns
- [x] Keep Block 3 (Cleanup): Preserve Phase 8 results display
- [x] Verify block count reduction: 8 blocks → 3 blocks (63% reduction)
- [x] Test end-to-end workflow to verify all 5 agents execute correctly

**Testing**:
```bash
# Block count verification
grep -c "^set -" .claude/commands/setup.md  # Should be 4
grep -c "^set -" .claude/commands/optimize-claude.md  # Should be 3

# Functionality verification
/setup --validate  # All modes work
/optimize-claude  # All agents execute
```

**Expected Duration**: 2-3 hours (1-1.5 hours per command)

---

### Phase 3: Documentation and Consistency [COMPLETE]
dependencies: [2]

**Objective**: Improve guide files, standardize agent invocation patterns, and ensure comprehensive troubleshooting coverage.

**Complexity**: Medium

**Tasks**:

#### /setup Guide File Improvements (90 minutes)
- [x] Extract setup modes detailed guide to `.claude/docs/guides/setup/setup-modes-detailed.md` (current lines 266-600 from setup-command-guide.md)
- [x] Extract extraction strategies guide to `.claude/docs/guides/setup/extraction-strategies.md` (current lines 601-900)
- [x] Extract testing detection guide to `.claude/docs/guides/setup/testing-detection-guide.md` (current lines 901-1100)
- [x] Extract CLAUDE.md templates to `.claude/docs/guides/setup/claude-md-templates.md` (current lines 1101-1240)
- [x] Expand troubleshooting section in main guide from 4 scenarios to 10+ scenarios (file: .claude/docs/guides/commands/setup-command-guide.md)
- [x] Add integration section documenting /setup → /optimize-claude workflow
- [x] Add migration guide for existing projects
- [x] Add performance tuning section for large codebases
- [x] Update table of contents with new section references
- [x] Add "See Also" links to extracted guides

#### /optimize-claude Guide File Enhancement (90 minutes)
- [x] Add "Agent Development Section" (100 lines) documenting how to create new analyzer agents (file: .claude/docs/guides/commands/optimize-claude-command-guide.md)
- [x] Add agent behavioral guidelines template with integration checklist
- [x] Add example: Creating a custom-rule-analyzer agent
- [x] Add "Customization Guide" (80 lines) documenting threshold configuration, agent selection, custom bloat rules
- [x] Expand troubleshooting section from 4 to 12+ scenarios (agent timeout, report failures, bloat edge cases, false positives, plan failures, /implement integration)
- [x] Add "Performance Optimization" section (60 lines) with parallel execution metrics, caching strategies, incremental optimization
- [x] Add workflow integration section for /setup → /optimize-claude → /implement
- [x] Update table of contents with new sections

#### Agent Integration Consistency (30 minutes)
- [x] Update /setup Phase 6 to use Task tool instead of SlashCommand (file: .claude/commands/setup.md, lines 292-307)
- [x] Add behavioral injection pattern with reference to orchestrate.md agent file
- [x] Add workflow context parameters (PROJECT_DIR, goal, phases)
- [x] Add completion signal parsing with `grep -q "WORKFLOW_COMPLETE"`
- [x] Add error logging for agent failure using `log_command_error()` with agent_error type
- [x] Test enhancement mode: `/setup --enhance-with-docs` to verify agent invocation works

#### Output Suppression Completeness (30 minutes per command)
- [x] Audit all library sourcing in /setup for `2>/dev/null` pattern
- [x] Update optimize-claude-md.sh invocation (line 160) to suppress non-error output: `2>&1 | grep -E "^(ERROR|WARN|✓)" || true`
- [x] Review all echo statements in /setup and consolidate to single summary per block
- [x] Audit all library sourcing in /optimize-claude for `2>/dev/null` pattern
- [x] Review all echo statements in /optimize-claude and consolidate to single summary per block
- [x] Test output cleanliness by running both commands and verifying minimal noise

**Testing**:
```bash
# Guide file completeness check
ls -la .claude/docs/guides/setup/  # Should have 4 new files
wc -l .claude/docs/guides/commands/setup-command-guide.md  # Should be reduced
wc -l .claude/docs/guides/commands/optimize-claude-command-guide.md  # Should be increased

# Agent integration test
/setup --enhance-with-docs  # Should use Task tool, return WORKFLOW_COMPLETE

# Output suppression test
/setup 2>&1 | wc -l  # Should have minimal output
/optimize-claude 2>&1 | grep -v "^$" | wc -l  # Should have clean output
```

**Expected Duration**: 4-5 hours (2-2.5 hours per command)

---

### Phase 4: Enhancement Features [COMPLETE]
dependencies: [3]

**Objective**: Add user-facing enhancement features for improved usability and flexibility.

**Complexity**: Low

**Tasks**:

#### Threshold Configuration for /optimize-claude (60 minutes)
- [x] Add argument parsing for --threshold flag with values (aggressive|balanced|conservative) (file: .claude/commands/optimize-claude.md, Phase 1)
- [x] Add shorthand flags: --aggressive, --balanced, --conservative
- [x] Add threshold validation with error logging for invalid values
- [x] Set default threshold to "balanced"
- [x] Export THRESHOLD variable for agent access
- [x] Update claude-md-analyzer agent invocation (Phase 2) to pass THRESHOLD parameter in prompt
- [x] Document threshold profiles in guide file with line count thresholds (aggressive: >50, balanced: >80, conservative: >120)
- [x] Add usage examples to guide: `/optimize-claude --threshold aggressive`

#### Dry-Run Support for /optimize-claude (60 minutes)
- [x] Add argument parsing for --dry-run flag (file: .claude/commands/optimize-claude.md, Phase 1)
- [x] Add dry-run logic after path allocation to preview workflow without execution
- [x] Display workflow stages: Research (2 agents), Analysis (2 agents), Planning (1 agent)
- [x] Display artifact paths that would be created
- [x] Display estimated execution time (3-5 minutes)
- [x] Exit with status 0 after preview
- [x] Document dry-run mode in guide with usage example: `/optimize-claude --dry-run`

#### File Flag Support for /optimize-claude (60 minutes)
- [x] Add argument parsing for --file flag to accept additional report paths (file: .claude/commands/optimize-claude.md, Phase 1)
- [x] Add file validation with error logging for invalid paths
- [x] Support multiple --file flags for passing multiple reports
- [x] Export ADDITIONAL_REPORTS variable containing paths array
- [x] Update research phase (Phase 2) to pass additional reports to research agents in prompt
- [x] Modify agent invocation to include: "Additional Reports: $ADDITIONAL_REPORTS" in context
- [x] Document --file flag in guide with usage example: `/optimize-claude --file path/to/report.md --file path/to/another.md`
- [x] Add test case for multi-file input validation

**Testing**:
```bash
# Threshold configuration test
/optimize-claude --threshold aggressive  # Should pass threshold to agent
/optimize-claude --conservative  # Shorthand should work

# Dry-run test
/optimize-claude --dry-run  # Should preview without execution

# File flag test
/optimize-claude --file /path/to/analysis.md  # Should pass report to research phase
/optimize-claude --file report1.md --file report2.md  # Multiple files should work
```

**Expected Duration**: 3 hours

---

## Testing Strategy

### Test Suite Architecture

**Test Files**:
- `.claude/tests/test_setup_command.sh` - Integration tests for all 6 modes
- `.claude/tests/test_setup_error_logging.sh` - Error logging integration tests
- `.claude/tests/test_optimize_claude_command.sh` - Integration tests for agent workflow
- `.claude/tests/test_optimize_claude_error_logging.sh` - Error logging integration tests
- `.claude/tests/test_command_modernization.sh` - Cross-command workflow tests

### Test Coverage Requirements

**Per-Command Coverage** (80% minimum):
- Mode detection and argument parsing
- Validation errors (logged and queryable)
- File creation and verification
- Standards integration (detect-testing.sh, generate-testing-protocols.sh for /setup)
- Error logging integration (all exit points)
- Bash block count verification
- Agent invocation (behavioral injection pattern)

**Cross-Command Integration**:
- /setup → /optimize-claude workflow
- /optimize-claude → /implement workflow
- Error logging integration with /errors command
- Standards compliance validation

### Validation Checklist

**Pre-Deployment**:
- [ ] All test suites pass (100% pass rate)
- [ ] Error logging compliance verified (test_error_logging_compliance.sh)
- [ ] Bash block count verified (manual inspection and grep -c)
- [ ] Guide files comprehensive (manual review with 90%+ coverage)
- [ ] Cross-references validated (no broken links)
- [ ] No regressions in existing functionality
- [ ] Performance metrics recorded (execution time before/after)

## Documentation Requirements

### Guide Files to Update

1. **Setup Command Guide** (.claude/docs/guides/commands/setup-command-guide.md)
   - Extract embedded sections to separate files
   - Expand troubleshooting from 4 to 10+ scenarios
   - Add integration workflows
   - Add migration guide

2. **Optimize-Claude Command Guide** (.claude/docs/guides/commands/optimize-claude-command-guide.md)
   - Add agent development section (100 lines)
   - Add customization guide (80 lines)
   - Expand troubleshooting to 12+ scenarios
   - Add performance optimization section (60 lines)

3. **New Guide Files** (.claude/docs/guides/setup/)
   - setup-modes-detailed.md
   - extraction-strategies.md
   - testing-detection-guide.md
   - claude-md-templates.md

### Documentation Standards

- Follow CommonMark specification
- Use clear, concise language
- Include code examples with syntax highlighting
- Add cross-references to related documentation
- Remove historical commentary
- No emojis in file content

## Dependencies

### External Dependencies
- error-handling.sh library (centralized error logging)
- unified-location-detection.sh library (topic path allocation)
- detect-testing.sh library (/setup framework detection)
- generate-testing-protocols.sh library (/setup protocol generation)
- optimize-claude-md.sh library (/setup cleanup mode)

### Prerequisites
- CLAUDE.md exists for /optimize-claude to analyze
- .claude/docs/ directory exists for documentation analysis
- Git repository initialized for project detection
- jq installed for JSON parsing in error context

### Integration Points
- /errors command (error queryability)
- /orchestrate workflow (/setup enhancement mode)
- /implement command (plan execution)
- Error log file (.claude/logs/errors.jsonl)

## Migration Strategy

### Phased Timeline

**Week 1: Phase 1 - Error Logging**
- Days 1-2: /setup error logging integration
- Days 3-4: /optimize-claude error logging integration
- Day 5: Testing and verification

**Week 2: Phase 2 - Bash Block Consolidation**
- Days 1-2: /setup block consolidation
- Days 3-4: /optimize-claude block consolidation
- Day 5: Testing and verification

**Week 3: Phase 3 - Documentation and Consistency**
- Days 1-2: Guide file improvements
- Day 3: Agent integration consistency
- Day 4: Output suppression completeness
- Day 5: Testing and validation

**Week 4: Phase 4 - Enhancement Features**
- Day 1: Threshold configuration
- Day 2: Dry-run support
- Day 3: File flag support for /optimize-claude
- Days 4-5: Testing and documentation

### Backup Strategy

**Pre-Migration Backups**:
```bash
mkdir -p .claude/backups/commands/
cp .claude/commands/setup.md .claude/backups/commands/setup.md.before-modernization
cp .claude/commands/optimize-claude.md .claude/backups/commands/optimize-claude.md.before-modernization
cp .claude/docs/guides/commands/setup-command-guide.md .claude/backups/commands/setup-command-guide.md.before-modernization
cp .claude/docs/guides/commands/optimize-claude-command-guide.md .claude/backups/commands/optimize-claude-command-guide.md.before-modernization
git tag setup-optimize-modernization-start
```

**Per-Phase Tags**:
- setup-optimize-phase1-complete (after error logging)
- setup-optimize-phase2-complete (after block consolidation)
- setup-optimize-phase3-complete (after documentation)
- setup-optimize-phase4-complete (after enhancement features)

### Rollback Procedures

**Full Rollback**:
```bash
git checkout setup-optimize-modernization-start
# OR
cp .claude/backups/commands/*.before-modernization .claude/commands/
```

**Single Phase Rollback**:
```bash
git revert <phase-commit-hash>
git checkout setup-optimize-phase1-complete -- .claude/commands/
bash .claude/tests/test_setup_command.sh
bash .claude/tests/test_optimize_claude_command.sh
```

## Risk Analysis

### Implementation Risks

**Risk 1: Breaking Existing Workflows** (Medium Likelihood, High Impact)
- Mitigation: Extensive testing (80%+ coverage), backward compatibility validation, rollback plan, phased migration

**Risk 2: Bash Block Consolidation Logic Errors** (Medium Likelihood, Medium Impact)
- Mitigation: Careful review of consolidated blocks, verify operation order dependencies, test each block independently

**Risk 3: Error Logging Performance Overhead** (Low Likelihood, Low Impact)
- Mitigation: Performance testing, error logging is <10ms per call, append-only with no locking

### Adoption Risks

**Risk 1: User Confusion with Error Logging** (Low Likelihood, Low Impact)
- Mitigation: Document error logging in guide files, add examples in troubleshooting, error messages suggest checking /errors

**Risk 2: Guide File Comprehension** (Medium Likelihood, Medium Impact)
- Mitigation: Clear structure with table of contents, progressive disclosure, examples throughout, cross-references

### Success Metrics

**Quantitative**:
- Error logging coverage: 0% → 100%
- Bash block count: /setup 6→4 (33%), /optimize-claude 8→3 (63%)
- Guide completeness: 70% → 90%
- Test coverage: 0% → 80%
- Error queryability: N/A → 100%

**Qualitative**:
- User feedback: "Errors are debuggable with /errors command"
- Developer feedback: "Guide files are comprehensive and helpful"
- Execution observation: "Output is clean and professional"
- Maintenance assessment: "Commands easier to understand and modify"

## Completion Criteria

This plan will be considered complete when:

1. **All Phases 1-4 Complete**: Error logging integrated, bash blocks consolidated, documentation enhanced, and enhancement features implemented
2. **100% Test Pass Rate**: All test suites passing with 80%+ line coverage
3. **Standards Compliance**: 100% compliance with applicable .claude/docs/ standards (Standard 17, Pattern 8, Standard 14, Pattern 9, Pattern 10, Standard 11)
4. **Error Queryability**: All errors accessible via `/errors --command /setup` and `/errors --command /optimize-claude`
5. **No Regressions**: All existing functionality preserved and verified
6. **Performance Validation**: Execution time same or faster after block consolidation
7. **Guide Completeness**: 90%+ coverage with expanded troubleshooting sections
8. **User Validation**: Manual testing of all modes and workflows successful
9. **Enhancement Features Working**: Threshold configuration, dry-run mode, and --file flag fully functional

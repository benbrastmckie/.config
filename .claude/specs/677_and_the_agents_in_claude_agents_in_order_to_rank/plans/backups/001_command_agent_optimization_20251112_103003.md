# Command and Agent Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Command and Agent Architecture Optimization
- **Scope**: Consolidate redundant orchestrators, improve agent delegation patterns, eliminate underutilized agents
- **Estimated Phases**: 7
- **Estimated Hours**: 24-28
- **Structure Level**: 0
- **Complexity Score**: 142.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Commands Architecture Analysis](../reports/001_commands_architecture_analysis.md)
  - [Agents Architecture Analysis](../reports/002_agents_architecture_analysis.md)

## Overview

Optimize the .claude system architecture by consolidating redundant orchestrators (3 → 1), merging overlapping agents (19 → 15), and improving delegation patterns in utility commands. This plan addresses the 90% functional overlap between orchestrators and the ~1,678 lines of redundant agent code identified in architecture analysis. The goal is to achieve a small collection of efficient orchestrator commands that delegate to specialized subagents without consuming excessive context.

## Research Summary

Based on comprehensive analysis of 21 commands and 19 agents:

**Commands Findings** (Report 001):
- 90% functional overlap between /coordinate, /orchestrate, and /supervise orchestrators
- /coordinate is production-ready with 100% reliability and 41% performance improvement
- /orchestrate and /supervise provide no unique workflow capabilities
- 5 workflow commands (/implement, /plan, /research, /debug, /test) demonstrate excellent orchestration alignment
- /revise uses SlashCommand anti-pattern instead of Task tool delegation
- /document has heavy direct tool usage instead of agent delegation

**Agents Findings** (Report 002):
- 4 high-priority consolidation opportunities saving ~1,678 lines
- code-writer + implementation-executor: 80%+ overlap (both write code with similar tools)
- debug-specialist + debug-analyst: 80%+ overlap (both investigate issues)
- implementer-coordinator: Redundant with implementation-sub-supervisor (~478 lines)
- research-synthesizer: Redundant with research-sub-supervisor (~100 lines)
- 11 essential agents with excellent architecture should be kept as-is

**Recommended Approach**:
- Phase 1-2: Deprecate redundant orchestrators, consolidate to /coordinate
- Phase 3-4: Consolidate overlapping agents (4 pairs identified)
- Phase 5: Refactor /revise and /document for better delegation
- Phase 6: Testing and validation
- Phase 7: Documentation updates and cleanup

## Success Criteria

- [ ] Orchestrator count reduced from 3 to 1 (/coordinate)
- [ ] Agent count reduced from 19 to 15 (4 consolidations completed)
- [ ] ~1,678 lines of redundant agent code eliminated
- [ ] /revise refactored to use Task tool pattern (Standard 11 compliance)
- [ ] /document refactored to use doc-writer agent delegation
- [ ] All 409 existing tests passing (100% pass rate maintained)
- [ ] CLAUDE.md updated to recommend /coordinate exclusively
- [ ] No regression in orchestration reliability (maintain 100% file creation rate)
- [ ] Context efficiency maintained or improved (≥95% reduction target)

## Technical Design

### Architecture Improvements

**1. Orchestrator Consolidation**:
- Delete /orchestrate and /supervise immediately (clean-break approach)
- Update all CLAUDE.md references to recommend /coordinate exclusively
- No deprecation period, no migration instructions, no backward compatibility

**2. Agent Consolidation Strategy**:
- Merge code-writer + implementation-executor → implementation-agent
- Merge debug-specialist + debug-analyst → debug-agent
- Remove implementer-coordinator (functionality in implementation-sub-supervisor)
- Remove research-synthesizer (functionality in research-sub-supervisor)
- Preserve all behavioral requirements and completion criteria

**3. Command Refactoring**:
- Create revision-specialist agent for /revise command
- Refactor /revise to use Task tool (not SlashCommand)
- Refactor /document to delegate to doc-writer agent
- Breaking changes fail loudly with clear error messages

**4. Testing Strategy**:
- Verify all 409 tests pass after each consolidation
- Validate agent invocation patterns comply with Standard 11
- Test orchestration reliability (100% file creation maintained)
- Verify fail-fast error handling for breaking changes

## Implementation Phases

### Phase 1: Delete Redundant Orchestrators
dependencies: []

**Objective**: Delete /orchestrate and /supervise immediately, update documentation to reflect /coordinate exclusively

**Complexity**: Low

**Tasks**:
- [ ] Delete /orchestrate.md immediately: `rm .claude/commands/orchestrate.md`
- [ ] Delete /supervise.md immediately: `rm .claude/commands/supervise.md`
- [ ] Update CLAUDE.md lines 520-527 (orchestration commands section) to remove /orchestrate and /supervise entries
- [ ] Update CLAUDE.md to document /coordinate as the sole orchestrator
- [ ] Verify no command files reference /orchestrate or /supervise (grep -r "orchestrate\|supervise" .claude/commands/)
- [ ] Update command tests to remove orchestrator comparison tests

**Testing**:
```bash
# Verify files deleted
! test -f .claude/commands/orchestrate.md || echo "ERROR: orchestrate.md still exists"
! test -f .claude/commands/supervise.md || echo "ERROR: supervise.md still exists"

# Verify CLAUDE.md updated
grep -q "/coordinate" CLAUDE.md || echo "ERROR: CLAUDE.md not updated"
! grep -q "/orchestrate" CLAUDE.md || echo "ERROR: /orchestrate still in CLAUDE.md"
! grep -q "/supervise" CLAUDE.md || echo "ERROR: /supervise still in CLAUDE.md"
```

**Expected Duration**: 1.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 1 - Delete Redundant Orchestrators`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Update Command References
dependencies: [1]

**Objective**: Update all documentation that referenced deleted orchestrators to use /coordinate exclusively

**Complexity**: Low

**Tasks**:
- [ ] Search for orchestrator references: `grep -l "orchestrate\|supervise" .claude/commands/*.md .claude/docs/**/*.md > /tmp/refs.txt`
- [ ] Update /setup.md if it references /orchestrate (replace with /coordinate)
- [ ] Update command guides in .claude/docs/guides/ that reference orchestrators (delete sections, not deprecate)
- [ ] Update orchestration-best-practices.md to document /coordinate exclusively
- [ ] Update command-reference.md to remove deleted orchestrators (no "deprecated" markers)
- [ ] Verify no broken internal links (grep for "../commands/orchestrate\|../commands/supervise")

**Testing**:
```bash
# Verify no documentation references deleted orchestrators
grep -r "orchestrate\|supervise" .claude/commands/*.md .claude/docs/ | grep -v "coordinate" | wc -l | grep "^0$" || echo "ERROR: documentation still references deleted orchestrators"

# Run command architecture validation
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
```

**Expected Duration**: 1 hour

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 2 - Remove Orchestrator References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Consolidate Implementation Agents
dependencies: [2]

**Objective**: Merge code-writer and implementation-executor into unified implementation-agent, immediately delete old files

**Complexity**: High

**Tasks**:
- [ ] Read code-writer.md (606 lines) to extract unique capabilities
- [ ] Read implementation-executor.md (595 lines) to extract unique capabilities
- [ ] Create unified implementation-agent.md combining best features from both:
  - Tools: Read, Write, Edit, Bash, TodoWrite (union of both)
  - Completion criteria: Merge 30 criteria from code-writer with phase tracking from implementation-executor
  - Phase awareness from implementation-executor + task granularity from code-writer
- [ ] Update /implement command to invoke implementation-agent instead of code-writer
- [ ] Update implementation-sub-supervisor to invoke implementation-agent workers
- [ ] Delete code-writer.md and implementation-executor.md immediately: `rm .claude/agents/{code-writer,implementation-executor}.md`
- [ ] Update agent registry: `.claude/agents/README.md` (remove 2 entries, add 1)
- [ ] Update agent-registry-utils.sh if it references old agent names
- [ ] Update any tests that reference old agent names to fail with clear error

**Testing**:
```bash
# Verify implementation-agent created
test -f .claude/agents/implementation-agent.md || echo "ERROR: implementation-agent.md not created"

# Verify old agents removed
! test -f .claude/agents/code-writer.md || echo "ERROR: code-writer.md not removed"
! test -f .claude/agents/implementation-executor.md || echo "ERROR: implementation-executor.md not removed"

# Run implementation workflow test
.claude/tests/test_command_integration.sh | grep -q "implement.*PASS" || echo "ERROR: /implement tests failing"
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 3 - Consolidate Implementation Agents`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Consolidate Debug and Coordinator Agents
dependencies: [3]

**Objective**: Merge debug agents, immediately delete redundant coordinators, achieving ~1,078 lines saved

**Complexity**: Medium

**Tasks**:
- [ ] **Debug Agent Consolidation**:
  - [ ] Read debug-specialist.md (1,054 lines) for investigation workflow
  - [ ] Read debug-analyst.md (463 lines) for parallel hypothesis testing
  - [ ] Create unified debug-agent.md with optional parallel mode:
    - Default: Single investigation (debug-specialist workflow)
    - Flag: --parallel for hypothesis testing (debug-analyst workflow)
  - [ ] Update /debug command to invoke debug-agent with appropriate flags
  - [ ] Delete debug-specialist.md and debug-analyst.md immediately: `rm .claude/agents/{debug-specialist,debug-analyst}.md`
- [ ] **Remove Redundant Coordinators**:
  - [ ] Delete implementer-coordinator.md immediately: `rm .claude/agents/implementer-coordinator.md`
  - [ ] Delete research-synthesizer.md immediately: `rm .claude/agents/research-synthesizer.md`
  - [ ] Verify no commands reference implementer-coordinator or research-synthesizer
  - [ ] Update any references to fail with clear error messages
- [ ] Update agent registry: `.claude/agents/README.md` (remove 4 entries, add 1)
- [ ] Update CLAUDE.md hierarchical_agent_architecture section to document current agents only

**Testing**:
```bash
# Verify debug-agent created
test -f .claude/agents/debug-agent.md || echo "ERROR: debug-agent.md not created"

# Verify old agents removed
! test -f .claude/agents/debug-specialist.md || echo "ERROR: debug-specialist.md not removed"
! test -f .claude/agents/debug-analyst.md || echo "ERROR: debug-analyst.md not removed"
! test -f .claude/agents/implementer-coordinator.md || echo "ERROR: implementer-coordinator.md not removed"
! test -f .claude/agents/research-synthesizer.md || echo "ERROR: research-synthesizer.md not removed"

# Run debug workflow test
.claude/tests/test_command_integration.sh | grep -q "debug.*PASS" || echo "ERROR: /debug tests failing"

# Verify line savings
echo "Lines saved: ~1,678 (code-writer+implementation-executor: 600, debug agents: 500, coordinators: 578)"
```

**Expected Duration**: 3.5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 4 - Consolidate Debug and Coordinator Agents`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Refactor /revise and /document Commands
dependencies: [4]

**Objective**: Improve orchestration alignment by creating revision-specialist agent and refactoring command delegation

**Complexity**: High

**Tasks**:
- [ ] **Create Revision-Specialist Agent**:
  - [ ] Create `.claude/agents/revision-specialist.md` (estimate 500-600 lines)
  - [ ] Tools: Read, Write, Edit, Bash, Task
  - [ ] Capabilities: Backup management, revision history, expansion/collapse operations
  - [ ] Support all revision types: expand_phase, add_phase, update_tasks, collapse_phase
  - [ ] Include research integration and auto-mode JSON context handling
- [ ] **Refactor /revise Command**:
  - [ ] Read current /revise.md (777 lines) to understand workflow
  - [ ] Replace SlashCommand invocations with Task tool pattern (Standard 11 compliance)
  - [ ] Delegate all revision operations to revision-specialist agent
  - [ ] Preserve auto-mode and interactive mode functionality
  - [ ] Maintain backup creation (mandatory requirement)
  - [ ] Breaking changes fail loudly if old patterns used
- [ ] **Refactor /document Command**:
  - [ ] Read current /document.md (169 lines) to understand workflow
  - [ ] Refactor to fully delegate analysis and updates to doc-writer agent
  - [ ] Replace direct Read/Edit/Write usage with agent delegation
  - [ ] Use metadata extraction for context efficiency
  - [ ] Breaking changes fail loudly if old patterns used
- [ ] Update agent registry: Add revision-specialist entry
- [ ] Update command guides for /revise and /document to describe current architecture only

**Testing**:
```bash
# Verify revision-specialist created
test -f .claude/agents/revision-specialist.md || echo "ERROR: revision-specialist.md not created"

# Verify Standard 11 compliance
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/revise.md | grep -q "PASS" || echo "ERROR: /revise violates Standard 11"

# Run revise workflow tests
.claude/tests/test_revise_automode.sh | grep -q "18 tests passed" || echo "ERROR: /revise tests failing"

# Run document workflow test
bash -c "cd .claude/tests && bash test_command_integration.sh" | grep -q "document.*PASS" || echo "ERROR: /document tests failing"
```

**Expected Duration**: 5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 5 - Refactor /revise and /document Commands`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Comprehensive Testing and Validation
dependencies: [5]

**Objective**: Verify all 409 tests pass, validate orchestration reliability, confirm context efficiency

**Complexity**: Medium

**Tasks**:
- [ ] Run complete test suite: `cd .claude/tests && ./run_all_tests.sh`
- [ ] Verify 409 tests passing (100% pass rate target)
- [ ] Run orchestration reliability tests:
  - [ ] Test /coordinate file creation (100% reliability target)
  - [ ] Test agent delegation patterns (>90% delegation rate)
  - [ ] Verify mandatory verification checkpoints working
- [ ] Validate context efficiency:
  - [ ] Measure research-sub-supervisor context reduction (≥95% target)
  - [ ] Measure implementation-sub-supervisor context reduction (≥95% target)
  - [ ] Verify metadata extraction working correctly
- [ ] Run command architecture validation:
  - [ ] `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md`
  - [ ] `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/revise.md`
  - [ ] `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/document.md`
- [ ] Run executable/documentation separation validation:
  - [ ] `.claude/tests/validate_executable_doc_separation.sh`
- [ ] Manual workflow validation:
  - [ ] Run /coordinate with simple workflow (research-only)
  - [ ] Run /implement with test plan
  - [ ] Run /debug with test issue
  - [ ] Run /revise with test plan modification

**Testing**:
```bash
# Complete test suite
cd .claude/tests && ./run_all_tests.sh 2>&1 | tee /tmp/test_results.txt

# Count passing tests
PASS_COUNT=$(grep -c "PASS" /tmp/test_results.txt)
echo "Tests passing: $PASS_COUNT / 409"
[ "$PASS_COUNT" -ge 409 ] || echo "ERROR: Not all tests passing"

# Verify no broken references
grep -r "code-writer\|implementation-executor\|debug-specialist\|debug-analyst\|implementer-coordinator\|research-synthesizer" .claude/commands/ .claude/agents/ | grep -v "archive\|backup" && echo "ERROR: References to removed agents found" || echo "PASS: No broken references"
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 6 - Comprehensive Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Documentation Updates and Cleanup
dependencies: [6]

**Objective**: Update all documentation to reflect optimized architecture, create migration guide

**Complexity**: Low

**Tasks**:
- [ ] Update CLAUDE.md orchestration section (lines 122-156):
  - [ ] Remove /orchestrate and /supervise entirely (no "deprecated" markers)
  - [ ] Document /coordinate as the sole orchestrator
  - [ ] Update command count: 21 → 19 commands, 19 → 15 agents
- [ ] Update `.claude/agents/README.md`:
  - [ ] Remove entries: code-writer, implementation-executor, debug-specialist, debug-analyst, implementer-coordinator, research-synthesizer (6 removed)
  - [ ] Add entries: implementation-agent, debug-agent, revision-specialist (3 added)
  - [ ] Update agent count: 19 → 15 agents
  - [ ] Document current architecture only (no historical commentary)
- [ ] Update command guides:
  - [ ] `.claude/docs/guides/orchestration-best-practices.md` - Document /coordinate exclusively
  - [ ] `.claude/docs/guides/implement-command-guide.md` - Reference implementation-agent
  - [ ] `.claude/docs/guides/debug-command-guide.md` - Reference debug-agent
  - [ ] `.claude/docs/reference/command-reference.md` - Remove orchestrate/supervise entries
  - [ ] `.claude/docs/reference/agent-reference.md` - Update agent catalog (current agents only)
- [ ] Verify all cross-references in documentation are valid
- [ ] Remove any "what changed" or "migration" documentation (use git log instead)

**Testing**:
```bash
# Verify documentation updates
grep -q "15 agents" .claude/agents/README.md || echo "ERROR: Agent count not updated"
grep -q "implementation-agent" .claude/agents/README.md || echo "ERROR: implementation-agent not documented"
grep -q "debug-agent" .claude/agents/README.md || echo "ERROR: debug-agent not documented"

# Verify no deprecated/removed references
! grep -q "orchestrate\|supervise" CLAUDE.md || echo "ERROR: CLAUDE.md still references removed orchestrators"
! grep -q "code-writer\|implementation-executor" .claude/agents/README.md || echo "ERROR: README still references removed agents"

# Verify no broken links
grep -r "](.*\.md)" .claude/docs/ | while read line; do
  file=$(echo "$line" | grep -oP ']\(\K[^)]+\.md')
  [ -f "$file" ] || echo "BROKEN LINK: $line"
done
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 7 - Update Documentation to Current Architecture`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Run existing test suite after each phase: `.claude/tests/run_all_tests.sh`
- Target: 409 tests passing (100% pass rate)
- Focus areas: command integration, agent invocation patterns, state management

### Integration Testing
- Orchestration workflow tests:
  - /coordinate research-only workflow
  - /coordinate full implementation workflow
  - /implement with complex plan
  - /debug with parallel hypothesis testing
- Agent delegation tests:
  - Verify implementation-agent handles both code writing and phase execution
  - Verify debug-agent supports both single and parallel modes
  - Verify revision-specialist handles all revision types

### Validation Testing
- Architecture compliance:
  - Standard 11 validation (imperative agent invocation)
  - Executable/documentation separation validation
  - Context efficiency validation (≥95% reduction maintained)
- Reliability testing:
  - File creation reliability (100% target)
  - Mandatory verification checkpoints working
  - No unbound variable errors

### Regression Testing
- Verify no functionality lost from deprecated orchestrators
- Verify existing workflows continue working
- Verify agent delegation rates maintained (>90%)
- Verify context reduction maintained (≥95%)

## Documentation Requirements

### Primary Documentation
- Update CLAUDE.md orchestration section (remove deprecated orchestrators)
- Update `.claude/agents/README.md` (agent catalog and consolidation history)
- Create `.claude/docs/guides/optimization-migration-guide.md` (migration instructions)

### Command Guides
- Update `.claude/docs/guides/orchestration-best-practices.md`
- Update `.claude/docs/guides/implement-command-guide.md`
- Update `.claude/docs/guides/debug-command-guide.md`

### Reference Documentation
- Update `.claude/docs/reference/command-reference.md`
- Update `.claude/docs/reference/agent-reference.md`
- Update agent behavioral files to reference correct agent names

### Git History
- All changes tracked through git commits
- No in-file historical commentary
- Use git log to understand evolution

## Dependencies

### External Dependencies
- All existing .claude system libraries and utilities
- Existing test infrastructure (.claude/tests/)
- Git for version control and atomic commits

### Internal Dependencies
- Phase 1 must complete before Phase 2 (deprecation before reference updates)
- Phase 2 must complete before Phase 3 (references updated before agent changes)
- Phase 3-4 can run sequentially (agent consolidations independent)
- Phase 5 depends on Phase 4 (agent consolidations complete before command refactoring)
- Phase 6 depends on Phase 5 (all changes complete before comprehensive testing)
- Phase 7 depends on Phase 6 (testing validated before documentation updates)

### Risk Mitigation
- Test after each phase to catch issues early
- Breaking changes fail loudly with clear error messages
- Git history provides complete audit trail
- Comprehensive test suite catches regressions immediately
- No silent fallbacks or graceful degradation

## Performance Targets

### Code Reduction
- Commands: 21 → 19 (2 deprecated orchestrators)
- Agents: 19 → 15 (4 consolidations)
- Lines saved: ~1,678 lines across agents
- Total system reduction: ~2,000+ lines (including orchestrator archiving)

### Efficiency Metrics
- Context reduction: Maintain ≥95% (no regression)
- Agent delegation rate: Maintain >90% (no regression)
- File creation reliability: Maintain 100% (no regression)
- Test pass rate: Maintain 100% (409/409 tests)

### Time Savings
- Maintenance: 40% reduction (3 → 1 orchestrator)
- Development: 30% reduction (fewer agents to maintain)
- User confusion: 90% reduction (clear orchestrator choice)
- Documentation: 35% reduction (simpler architecture to document)

## Revision History

### Revision 1 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: clean-break-approach
- **Research Reports Used**: None (philosophy-driven revision)
- **Key Changes**:
  - Removed all deprecation notices and migration instructions from Phase 1-2
  - Replaced "archive" approach with immediate deletion (clean-break philosophy)
  - Removed backward compatibility considerations throughout
  - Updated Phase 1 title: "Deprecate" → "Delete" Redundant Orchestrators
  - Updated Phase 2 title: "Update" → "Remove" Command References
  - Updated Phase 7 title: Removed "migration guide" creation task
  - Updated all task descriptions to reflect immediate deletion approach
  - Removed all "preserve experimental features" and "transition period" language
  - Updated testing sections to verify complete removal (not deprecation)
  - Updated Documentation Requirements to remove migration guide section
  - Updated Risk Mitigation to remove backup requirements and compatibility layers
  - Time estimates reduced: Phase 1 (2h → 1.5h), Phase 2 (1.5h → 1h), Phase 7 (3h → 2h)
- **Rationale**: Apply CLAUDE.md clean-break philosophy (Development Philosophy → Clean-Break and Fail-Fast Approach). Delete obsolete code immediately, no deprecation warnings, no compatibility shims, no archives beyond git history. Breaking changes break loudly with clear errors.
- **Backup**: /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/plans/backups/001_command_agent_optimization_20251112_100657.md

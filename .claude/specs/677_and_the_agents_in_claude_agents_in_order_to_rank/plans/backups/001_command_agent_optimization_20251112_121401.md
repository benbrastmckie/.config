# Command and Agent Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Command and Agent Architecture Optimization
- **Scope**: Consolidate redundant orchestrators, improve agent delegation patterns, eliminate underutilized agents
- **Estimated Phases**: 8
- **Estimated Hours**: 28-32
- **Structure Level**: 0
- **Complexity Score**: 142.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Commands Architecture Analysis](../reports/001_commands_architecture_analysis.md)
  - [Agents Architecture Analysis](../reports/002_agents_architecture_analysis.md)

## Overview

Optimize the .claude system architecture by consolidating redundant orchestrators (3 → 1), merging overlapping agents (19 → 15), and implementing complexity-based dynamic model routing. Research shows the system is already well-optimized (29% Haiku, 52% Sonnet, 19% Opus) with limited agent-level optimization remaining. The primary opportunity is implementing complexity-based dynamic routing in /research command for 24% cost reduction on research operations, rather than static agent downgrades.

## Research Summary

Based on comprehensive model usage analysis (Reports 001-002):

**Current Model Distribution** (Report 002):
- 6 Haiku agents (29%): spec-updater, doc-converter, implementer-coordinator, metrics-specialist, complexity-estimator, code-reviewer
- 11 Sonnet agents (52%): code-writer, doc-writer, test-specialist, github-specialist, research-specialist, research-synthesizer, implementation-executor, implementation-researcher, debug-analyst, revision-specialist, sub-supervisors
- 4 Opus agents (19%): plan-architect, plan-structure-manager, debug-specialist, expansion/collapse specialists
- **Assessment**: Well-balanced distribution, within ideal ranges (25-35% Haiku, 50-60% Sonnet, 10-20% Opus)

**Recent Optimization Success** (Spec 484):
- 3 agents migrated to Haiku: spec-updater, doc-converter, implementer-coordinator
- 1 agent upgraded to Opus: debug-specialist
- Net savings: $0.216/week (6-9% system-wide cost reduction)
- Quality retention: ≥95% maintained

**Primary Opportunity Identified** (Report 001):
- **Complexity-Based Dynamic Routing in /research**: 24% cost reduction on research operations
  - Simple topics (1 subtopic): Haiku for basic pattern discovery
  - Medium topics (2 subtopics): Sonnet (current baseline)
  - Complex topics (3-4 subtopics): Sonnet or Opus for architectural analysis
- **Savings**: ~$0.036/week, $1.87 annually

**Limited Agent-Level Optimization**:
- Only 2 low-confidence downgrade candidates identified:
  - testing-sub-supervisor: 40% confidence, 3.2% potential savings
  - implementation-sub-supervisor: 20% confidence, not recommended
- **Recommendation**: NOT worth migration risk (3.2% savings too small)

**Commands Architecture** (Report 001):
- 90% functional overlap between /coordinate, /orchestrate, and /supervise
- /coordinate production-ready, /orchestrate and /supervise provide no unique capabilities
- /revise uses SlashCommand anti-pattern (needs Task tool delegation)
- /document has heavy direct tool usage (needs agent delegation)

**Revised Approach**:
- Phase 1-2: Delete redundant orchestrators (clean-break, no deprecation)
- Phase 3-4: Consolidate overlapping agents (architectural cleanup, not cost optimization)
- Phase 5: Implement complexity-based dynamic routing in /research (PRIMARY OPTIMIZATION)
- Phase 6: Refactor /revise and /document for better delegation
- Phase 7: Testing and validation
- Phase 8: Documentation updates

## Success Criteria

- [ ] Orchestrator count reduced from 3 to 1 (/coordinate)
- [ ] Agent count reduced from 19 to 15 (4 consolidations completed)
- [ ] ~1,678 lines of redundant agent code eliminated
- [ ] **PRIMARY GOAL**: Complexity-based dynamic routing implemented in /research (24% cost reduction)
- [ ] /revise refactored to use Task tool pattern (Standard 11 compliance)
- [ ] /document refactored to use doc-writer agent delegation
- [ ] All 409 existing tests passing (100% pass rate maintained)
- [ ] CLAUDE.md updated to recommend /coordinate exclusively
- [ ] No regression in orchestration reliability (maintain 100% file creation rate)
- [ ] Context efficiency maintained or improved (≥95% reduction target)
- [ ] Research complexity routing validated: <5% error rate increase for Haiku invocations

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
- **Rationale**: Architectural cleanup to reduce maintenance burden, NOT for cost optimization (research shows 3.2% potential savings not worth migration risk)

**3. Complexity-Based Dynamic Routing (PRIMARY OPTIMIZATION)**:
- Implement in /research command Phase 0 (before research agent invocation)
- Research complexity scoring:
  - Simple (1 subtopic): Haiku 4.5 - basic pattern discovery
  - Medium (2 subtopics): Sonnet 4.5 - default baseline
  - Complex (3-4 subtopics): Sonnet 4.5 or Opus 4.1 - architectural analysis
- Pass model tier dynamically to Task invocation: `model: "$RESEARCH_MODEL"`
- Quality safeguards:
  - Monitor error rate for Haiku research (<5% increase threshold)
  - Fallback to Sonnet if validation fails
  - 2-week monitoring period before full rollout
- **Expected Impact**: 24% cost reduction on research operations ($1.87 annually)

**4. Command Refactoring**:
- Create revision-specialist agent for /revise command
- Refactor /revise to use Task tool (not SlashCommand)
- Refactor /document to delegate to doc-writer agent
- Breaking changes fail loudly with clear error messages

**5. Testing Strategy**:
- Verify all 409 tests pass after each consolidation
- Validate agent invocation patterns comply with Standard 11
- Test orchestration reliability (100% file creation maintained)
- Verify fail-fast error handling for breaking changes
- Validate complexity-based routing: error rate <5% increase for Haiku invocations

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

### Phase 5: Implement Complexity-Based Dynamic Routing in /research
dependencies: [4]

**Objective**: Implement dynamic model selection in /research command based on topic complexity (PRIMARY OPTIMIZATION)

**Complexity**: High

**Tasks**:
- [ ] **Analyze /research Command Structure**:
  - [ ] Read current /research.md to understand Phase 0 (research decomposition)
  - [ ] Identify where complexity scoring occurs (subtopic count calculation)
  - [ ] Locate research-specialist Task invocations (lines to modify)
- [ ] **Implement Complexity-Based Model Selection**:
  - [ ] Add model selection logic in Phase 0 (before research agent invocation):
    ```bash
    # Calculate research complexity based on subtopic count
    SUBTOPIC_COUNT=$(echo "$RESEARCH_TOPICS" | wc -l)

    case "$SUBTOPIC_COUNT" in
      1)  # Simple topics - basic pattern discovery
          RESEARCH_MODEL="haiku-4.5"
          ;;
      2)  # Medium topics - default baseline
          RESEARCH_MODEL="sonnet-4.5"
          ;;
      3|4)  # Complex topics - architectural analysis
          RESEARCH_MODEL="sonnet-4.5"  # Consider opus for critical architecture
          ;;
      *)  # Very complex (>4 subtopics) - fallback to Sonnet
          RESEARCH_MODEL="sonnet-4.5"
          ;;
    esac
    ```
  - [ ] Update research-specialist Task invocation to pass model dynamically:
    ```yaml
    Task {
      subagent_type: "general-purpose"
      model: "$RESEARCH_MODEL"
      description: "Research $SUBTOPIC"
      ...
    }
    ```
  - [ ] Add logging for model selection decisions: `echo "Research complexity: $SUBTOPIC_COUNT subtopics → Model: $RESEARCH_MODEL"`
- [ ] **Add Quality Safeguards**:
  - [ ] Implement error rate tracking for Haiku invocations
  - [ ] Add fallback logic: If Haiku research fails validation, retry with Sonnet
  - [ ] Document rollback trigger: >5% error rate increase
- [ ] **Update Model Selection Guide**:
  - [ ] Add /research complexity-based routing pattern to Model Selection Guide
  - [ ] Document decision criteria (subtopic count → model tier)
  - [ ] Include monitoring requirements (2-week observation period)
- [ ] Update /research command guide to document dynamic routing

**Testing**:
```bash
# Test simple research (1 subtopic) - should use Haiku
/research "Find all files implementing authentication" | grep "Model: haiku-4.5"

# Test medium research (2 subtopics) - should use Sonnet
/research "Analyze authentication patterns and security implementations" | grep "Model: sonnet-4.5"

# Test complex research (3-4 subtopics) - should use Sonnet
/research "Investigate authentication, authorization, session management, and security audit patterns" | grep "Model: sonnet-4.5"

# Verify error rate tracking
grep "Research.*haiku.*error" .claude/data/logs/adaptive-planning.log | wc -l

# Verify fallback logic
# (Manual test: Force Haiku failure, verify Sonnet retry)
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 5 - Implement Complexity-Based Dynamic Routing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Refactor /revise and /document Commands
dependencies: [5]

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

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 6 - Refactor /revise and /document Commands`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Comprehensive Testing and Validation
dependencies: [6]

**Objective**: Verify all 409 tests pass, validate orchestration reliability, confirm context efficiency, validate complexity-based routing

**Complexity**: Medium

**Tasks**:
- [ ] Run complete test suite: `cd .claude/tests && ./run_all_tests.sh`
- [ ] Verify 409 tests passing (100% pass rate target)
- [ ] **Validate Complexity-Based Routing** (PRIMARY VALIDATION):
  - [ ] Test simple research (1 subtopic): Verify Haiku model selection and error rate <5%
  - [ ] Test medium research (2 subtopics): Verify Sonnet model selection (baseline)
  - [ ] Test complex research (3-4 subtopics): Verify Sonnet/Opus model selection
  - [ ] Monitor error rate for 2 weeks: Track Haiku research failures vs Sonnet baseline
  - [ ] Verify fallback logic: Confirm Haiku failures retry with Sonnet
  - [ ] Measure cost reduction: Compare research costs before/after implementation (target: 24% reduction)
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
  - [ ] `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md` (complexity routing validation)
- [ ] Run executable/documentation separation validation:
  - [ ] `.claude/tests/validate_executable_doc_separation.sh`
- [ ] Manual workflow validation:
  - [ ] Run /coordinate with simple workflow (research-only)
  - [ ] Run /implement with test plan
  - [ ] Run /debug with test issue
  - [ ] Run /revise with test plan modification
  - [ ] Run /research with simple, medium, and complex topics (verify model routing)

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

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 7 - Comprehensive Testing and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 8: Documentation Updates and Cleanup
dependencies: [7]

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

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 8 - Update Documentation to Current Architecture`
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
- Phase 1 must complete before Phase 2 (deletion before reference updates)
- Phase 2 must complete before Phase 3 (references updated before agent changes)
- Phase 3-4 can run sequentially (agent consolidations independent)
- Phase 5 depends on Phase 4 (agent consolidations complete before complexity routing)
- Phase 6 depends on Phase 5 (complexity routing complete before command refactoring)
- Phase 7 depends on Phase 6 (all changes complete before comprehensive testing)
- Phase 8 depends on Phase 7 (testing validated before documentation updates)

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

### Cost Optimization (NEW - Phase 5)
- Research operation cost: 24% reduction via complexity-based routing
- Annual savings: $1.87 (baseline: 10 research invocations/week)
- Quality safeguards: <5% error rate increase threshold, 2-week monitoring period
- Haiku research allocation: ~30% of invocations (simple topics only)

## Revision History

### Revision 2 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: research-informed
- **Research Reports Used**:
  - /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/reports/001_command_model_analysis.md
  - /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/reports/002_agent_model_analysis.md
- **Key Changes**:
  - Updated Overview to reflect research finding: system already well-optimized (29% Haiku, 52% Sonnet, 19% Opus)
  - Expanded Research Summary with comprehensive model distribution analysis and Spec 484 optimization success
  - Added Primary Opportunity: Complexity-based dynamic routing in /research (24% cost reduction, $1.87 annually)
  - Documented Limited Agent-Level Optimization: Only 2 low-confidence candidates (3.2% savings not worth risk)
  - Updated Phase count: 7 → 8 phases (added new Phase 5 for complexity routing)
  - Updated Estimated Hours: 24-28 → 28-32 hours
  - Added NEW Phase 5: Implement Complexity-Based Dynamic Routing in /research (4 hours)
  - Renumbered subsequent phases: Old Phase 5-7 → New Phase 6-8
  - Updated Success Criteria: Added PRIMARY GOAL for complexity routing and validation threshold
  - Updated Technical Design: Added Section 3 (Complexity-Based Dynamic Routing) with implementation details
  - Updated Technical Design: Added rationale to Agent Consolidation (architectural cleanup, not cost optimization)
  - Enhanced Phase 7: Added comprehensive complexity routing validation tasks
  - Updated Dependencies section: Adjusted phase dependency chain
  - Added Cost Optimization section to Performance Targets: 24% research cost reduction details
- **Rationale**: Research shows system already optimally distributed across model tiers post-Spec 484 (6-9% cost reduction achieved). Further agent-level optimization has minimal ROI (3.2% savings). Primary opportunity is dynamic model selection based on task complexity within commands (24% cost reduction on research operations). Shift focus from static agent downgrades to complexity-based routing.
- **Backup**: /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/plans/backups/001_command_agent_optimization_20251112_103003.md

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

# Command and Agent Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Command and Agent Architecture Optimization
- **Scope**: Consolidate redundant orchestrators, improve agent delegation patterns, eliminate underutilized agents, implement dynamic routing in /research command
- **Estimated Phases**: 7
- **Estimated Hours**: 25-29
- **Structure Level**: 0
- **Complexity Score**: 142.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Commands Architecture Analysis](../reports/001_commands_architecture_analysis.md)
  - [Agents Architecture Analysis](../reports/002_agents_architecture_analysis.md)
  - [Comprehensive Haiku Classification Architecture](/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/001_haiku_classification_architecture.md) (IMPLEMENTED in Spec 678)
  - [Optimization Plan Revision Needs](/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/002_optimization_plan_revision_needs.md)

## Overview

Optimize the .claude system architecture by consolidating redundant orchestrators (3 → 1), merging overlapping agents (19 → 15), and implementing complexity-based dynamic routing in /research command (24% cost reduction). Research shows the system is already well-optimized (29% Haiku, 52% Sonnet, 19% Opus) with limited agent-level optimization remaining. Note: Comprehensive haiku-based workflow classification (Spec 678) has been completed externally and eliminates all pattern matching for WORKFLOW_SCOPE and RESEARCH_COMPLEXITY. This plan focuses on leveraging that infrastructure for command-level optimizations.

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
- Phase 5: Refactor /revise and /document for better delegation, implement dynamic routing in /research (PRIMARY OPTIMIZATION)
- Phase 6: Testing and validation
- Phase 7: Documentation updates

**Integration with Spec 678**: Spec 678 has fully implemented comprehensive haiku-based workflow classification, eliminating all pattern matching for WORKFLOW_SCOPE and RESEARCH_COMPLEXITY detection. The infrastructure exports RESEARCH_COMPLEXITY (1-4) and RESEARCH_TOPICS_JSON via sm_init(), enabling dynamic model selection in commands. This plan leverages that infrastructure to implement complexity-based routing in /research command.

## Success Criteria

- [ ] Orchestrator count reduced from 3 to 1 (/coordinate)
- [ ] Agent count reduced from 19 to 15 (4 consolidations completed)
- [ ] ~1,678 lines of redundant agent code eliminated
- [ ] Complexity-based dynamic routing implemented in /research (24% cost reduction)
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

**3. Dynamic Routing in /research (Uses Spec 678 Infrastructure)**:

Spec 678 implemented comprehensive haiku-based classification that provides RESEARCH_COMPLEXITY (1-4) via sm_init(). This optimization integrates that infrastructure into /research command for complexity-based model selection:

**Model Selection Strategy**:
- Simple (1 subtopic): Haiku 4.5 - basic pattern discovery
- Medium (2 subtopics): Sonnet 4.5 - default baseline
- Complex (3-4 subtopics): Sonnet 4.5 or Opus 4.1 - architectural analysis

**Implementation Approach**:
- Load RESEARCH_COMPLEXITY from workflow state (set during /coordinate sm_init)
- Add model selection logic in /research command Phase 0
- Pass model dynamically to research-specialist Task invocations
- Use RESEARCH_TOPICS_JSON for descriptive subtopic names (not generic "Topic N")

**Quality Safeguards**:
- Monitor error rate for Haiku research (<5% increase threshold)
- Fallback to Sonnet if validation fails
- 2-week monitoring period before full rollout

**Expected Impact**:
- 24% cost reduction on research operations ($1.87 annually)
- Haiku adequate for simple pattern discovery
- Maintains quality for complex architectural analysis

See [Spec 678 reports](../../../678_coordinate_haiku_classification/reports/) for comprehensive classification architecture and implementation details.

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

### Phase 5: Refactor /revise and /document Commands, Implement Dynamic Routing
dependencies: [4]

**Objective**: Improve orchestration alignment by creating revision-specialist agent, refactoring command delegation, and implementing complexity-based dynamic routing in /research command (PRIMARY OPTIMIZATION)

**Complexity**: High

**Tasks**:
- [ ] **Implement Dynamic Routing in /research**:
  - [ ] Read current /research.md to understand Phase 0 (research decomposition)
  - [ ] Add model selection logic in /research Phase 0 to use RESEARCH_COMPLEXITY from workflow state
  - [ ] Implement case statement for model selection:
    ```bash
    case "$RESEARCH_COMPLEXITY" in
      1)  RESEARCH_MODEL="haiku-4.5" ;;      # Simple topics
      2)  RESEARCH_MODEL="sonnet-4.5" ;;     # Medium topics (baseline)
      3|4) RESEARCH_MODEL="sonnet-4.5" ;;    # Complex topics
      *)  RESEARCH_MODEL="sonnet-4.5" ;;     # Fallback to Sonnet
    esac
    ```
  - [ ] Update research-specialist Task invocations to pass model dynamically: `model: "$RESEARCH_MODEL"`
  - [ ] Use RESEARCH_TOPICS_JSON for descriptive subtopic names in agent prompts (not generic "Topic N")
  - [ ] Add logging: `echo "Research complexity: $RESEARCH_COMPLEXITY subtopics → Model: $RESEARCH_MODEL"`
  - [ ] Implement error rate tracking for Haiku invocations in /research
  - [ ] Add fallback logic: If Haiku research fails validation, retry with Sonnet
  - [ ] Update Model Selection Guide with /research complexity-based routing pattern
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

**Expected Duration**: 6 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(677): complete Phase 5 - Refactor Commands and Implement Dynamic Routing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Comprehensive Testing and Validation
dependencies: [5]

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
- Phase 1 must complete before Phase 2 (deletion before reference updates)
- Phase 2 must complete before Phase 3 (references updated before agent changes)
- Phase 3-4 can run sequentially (agent consolidations independent)
- Phase 5 depends on Phase 4 (agent consolidations complete before command refactoring and dynamic routing)
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

### Cost Optimization (NEW - Phase 5)
- Research operation cost: 24% reduction via complexity-based routing
- Annual savings: $1.87 (baseline: 10 research invocations/week)
- Quality safeguards: <5% error rate increase threshold, 2-week monitoring period
- Haiku research allocation: ~30% of invocations (simple topics only)

## Revision History

### Revision 4 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: research-informed (specs 678/683 implementation completed externally)
- **Research Reports Used**:
  - /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/001_haiku_classification_architecture.md
  - /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/002_optimization_plan_revision_needs.md
- **Key Changes**:
  - **Metadata**: Updated Estimated Phases from 8 to 7 (Phase 5 deleted)
  - **Metadata**: Updated Estimated Hours from 30-34 to 25-29 hours (removed 6 hours from deleted Phase 5, added 1 hour for dynamic routing in new Phase 5)
  - **Metadata**: Updated Complexity Score from 150.5 to 142.5 (removed Phase 5 tasks)
  - **Metadata**: Updated Research Reports to include Spec 678 reports (IMPLEMENTED status)
  - **Metadata**: Updated Scope to replace "integrate comprehensive haiku classification" with "implement dynamic routing in /research command"
  - **Overview**: Revised to note Spec 678 comprehensive classification already completed externally
  - **Overview**: Removed references to implementing comprehensive haiku classification (already done)
  - **Research Summary**: Updated Integration with Spec 678 to reflect completed implementation
  - **Success Criteria**: Removed 4 obsolete criteria related to comprehensive classification (PRIMARY GOAL, haiku classification returns, diagnostic message confusion)
  - **Success Criteria**: Retained complexity-based dynamic routing criterion (moved to Phase 5)
  - **Technical Design Section 3**: Completely replaced comprehensive classification architecture with brief reference to Spec 678 and focus on dynamic routing implementation
  - **Revised Approach**: Updated to reflect 7 phases (not 8), combined command refactoring and dynamic routing in Phase 5
  - **Phase 5 DELETED**: Entire phase "Implement Comprehensive Haiku Classification" removed (100% implemented in specs 678/683)
  - **Phase 6→5**: Renamed "Refactor /revise and /document Commands" to include dynamic routing implementation
  - **Phase 5 Tasks**: Added 8 new tasks for dynamic routing in /research command (moved from deleted Phase 5)
  - **Phase 5 Duration**: Increased from 5 to 6 hours (+1 hour for dynamic routing implementation)
  - **Phase 7→6**: Renumbered "Comprehensive Testing and Validation"
  - **Phase 8→7**: Renumbered "Documentation Updates and Cleanup"
  - **Dependencies**: Updated all phase dependencies to reflect new numbering (Phase 5 depends on [4], Phase 6 depends on [5], Phase 7 depends on [6])
  - **Completion Requirements**: Updated git commit messages for all phases to reflect new numbering
- **Rationale**: Spec 678 (comprehensive haiku classification) and Spec 683 (critical bug fixes) have been fully implemented, completing 100% of original Phase 5 work. All pattern matching for workflow classification has been eliminated, RESEARCH_COMPLEXITY infrastructure is in place, and descriptive topic names are generated. The only remaining work is integrating the Spec 678 infrastructure into /research command for dynamic model selection (24% cost reduction). This revision removes obsolete work, consolidates remaining phases, and focuses plan on leveraging existing infrastructure.
- **Backup**: /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/plans/backups/001_command_agent_optimization_20251112_145623.md

### Revision 3 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: research-informed
- **Research Reports Used**:
  - /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md
- **Key Changes**:
  - **Metadata**: Added Spec 678 to Research Reports, updated Scope to include haiku classification integration
  - **Metadata**: Updated Estimated Hours from 28-32 to 30-34 hours (+2 hours for Phase 5 expansion)
  - **Metadata**: Updated Complexity Score from 142.5 to 150.5 (Phase 5 task additions)
  - **Overview**: Expanded to mention comprehensive haiku-based workflow classification from Spec 678
  - **Overview**: Added Integration with Spec 678 section explaining single haiku call for workflow_type, complexity, and subtopics
  - **Success Criteria**: Added PRIMARY GOAL for comprehensive haiku classification (zero pattern matching)
  - **Success Criteria**: Added criteria for haiku comprehensive classification returning all 3 dimensions
  - **Success Criteria**: Added diagnostic message confusion resolution (Issue 676)
  - **Technical Design Section 3**: Completely rewritten to include comprehensive classification architecture
  - **Technical Design Section 3**: Added architecture diagrams comparing current (Spec 670 + patterns) vs new (Spec 678 comprehensive)
  - **Technical Design Section 3**: Documented comprehensive classification integration with sm_init()
  - **Technical Design Section 3**: Added dynamic routing in /research using RESEARCH_COMPLEXITY from sm_init
  - **Technical Design Section 3**: Added quality safeguards and expected impact metrics
  - **Phase 5**: Title changed from "Implement Complexity-Based Dynamic Routing in /research" to "Implement Comprehensive Haiku Classification for Workflow Detection and Research Routing"
  - **Phase 5**: Objective expanded to include Spec 678 comprehensive classification integration (PRIMARY OPTIMIZATION)
  - **Phase 5**: Added task section: Analyze Current Workflow Classification Approach (5 subtasks)
  - **Phase 5**: Added task section: Implement Comprehensive Haiku Classification (7 subtasks)
  - **Phase 5**: Added task section: Remove Pattern Matching from coordinate.md (5 subtasks)
  - **Phase 5**: Expanded task section: Integrate with /research Dynamic Routing (8 subtasks, uses RESEARCH_COMPLEXITY from sm_init)
  - **Phase 5**: Added task section: Update Documentation (4 subtasks)
  - **Phase 5**: Enhanced testing to include comprehensive classification tests (22 test cases)
  - **Phase 5**: Increased duration from 4 hours to 6 hours (+2 hours for comprehensive classification implementation)
- **Rationale**: Spec 678 provides comprehensive haiku-based classification that eliminates ALL pattern matching for workflow detection. Integrating this into Phase 5 achieves both goals: (1) zero pattern matching for WORKFLOW_SCOPE and RESEARCH_COMPLEXITY, and (2) dynamic model routing in /research for 24% cost reduction. Single haiku call replaces two classification operations, providing workflow_type, research_complexity, and descriptive subtopic names. Also resolves Issue 676 diagnostic message confusion.
- **Backup**: /home/benjamin/.config/.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/plans/backups/001_command_agent_optimization_20251112_121401.md

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

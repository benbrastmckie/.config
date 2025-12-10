# Implementation Plan: Fix Research-Coordinator Pseudo-Code Task Invocation Issue

## Metadata

- **Date**: 2025-12-10
- **Feature**: Fix research-coordinator agent pseudo-code Task invocation pattern to comply with command authoring standards
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 8-12 hours
- **Complexity Score**: 68 (enhance=7 + tasks=18/2 + files=15*3 + integrations=2*5 = 7+9+45+10=71, adjusted to 68)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Create-Plan Output Analysis](../reports/001-create-plan-output-analysis.md)
  - [Research Coordinator Architecture](../reports/002-research-coordinator-architecture.md)
  - [Command Authoring Standards](../reports/003-command-authoring-standards.md)
  - [Fix Strategy Analysis](../reports/004-fix-strategy-analysis.md)

## Problem Statement

The research-coordinator agent (`.claude/agents/research-coordinator.md`) uses a Bash heredoc pattern in STEP 3 that outputs Task invocation text to stdout. The agent model treats this bash output as documentation rather than executable instructions, resulting in zero Task tool invocations and empty reports directories. This violates command authoring standards which require Task invocations to appear as static markdown with imperative directives (not dynamically generated via bash output).

**Root Cause**: Bash loop indirection pattern creates semantic gap between "execute bash that generates Task text" and "execute Task tool invocations". The agent cannot programmatically invoke tools based on text it reads from bash output.

**Evidence**:
- `/create-plan` output (line 65-68): Agent returned explanation that it outputted pseudo-code instead of executing Task tools
- research-coordinator.md STEP 3 (lines 373-405): Heredoc outputs `Task { ... }` patterns to stdout
- Command authoring standards (lines 99-343): Task invocations MUST be static markdown with `**EXECUTE NOW**` directives, NOT inside bash heredocs or code blocks

**Impact**: Critical - Coordinator cannot execute its core function (parallel research delegation), forcing primary agents to manually invoke research-specialist as workaround.

## Solution Summary

Implement **Option A (Remove Bash Loop Indirection)** as recommended by Fix Strategy Analysis report. Remove Task tool from research-coordinator's allowed-tools and STEP 3 Task invocations. Refactor `/research`, `/create-plan`, and `/lean-plan` commands to invoke research-specialist agents directly (without coordinator layer) following the pattern from hierarchical-agents-examples.md Example 1.

**Trade-off**: Accept loss of 95% context reduction (coordinator's metadata aggregation benefit) in exchange for architectural correctness and standards compliance. For 3-4 research topics, context cost (7,500-10,000 tokens) is acceptable within 200k context window.

## Implementation Phases

### Phase 1: Fix Research-Coordinator Agent File [COMPLETE]

**Objective**: Remove Task tool capability and Task invocations from research-coordinator.md, converting it to a planning-only coordinator that returns invocation metadata (not executes Task tools).

**Tasks**:
- [x] Remove `Task` from allowed-tools frontmatter (line 2)
- [x] Rewrite STEP 3 (lines 333-457) to return invocation plan instead of executing Task tools
  - [x] Replace Bash heredoc pattern with invocation metadata generation
  - [x] Output format: structured list of topics with pre-calculated report paths
  - [x] Return signal: `COORDINATOR_PLAN_READY: [topic_count] topics, [report_count] expected reports`
- [x] Update STEP 3.5 self-validation (lines 460-508) to verify invocation plan creation (not Task execution)
- [x] Update STEP 4 hard barrier (lines 511-657) to validate invocation plan file exists (not report files)
- [x] Update STEP 5-6 to return invocation plan metadata instead of report metadata

**Success Criteria**:
- [x] `allowed-tools` frontmatter does NOT include `Task`
- [x] STEP 3 contains NO `Task { }` blocks or `**EXECUTE NOW**` directives
- [x] Agent returns structured invocation plan with topics and report paths
- [x] All validation steps check invocation plan artifacts (not reports)

**Dependencies**: None

**Estimated Hours**: 2-3 hours

---

### Phase 2: Refactor /research Command for Direct Invocation [NOT STARTED]

**Objective**: Modify `/research` command to invoke research-specialist agents directly (without coordinator intermediary), following hierarchical-agents-examples.md Example 1 pattern.

**Tasks**:
- [ ] Read current `/research` command implementation (`.claude/commands/research.md`)
- [ ] Identify coordinator invocation blocks (Task tool calls to research-coordinator)
- [ ] Replace coordinator invocation with direct research-specialist invocations:
  - [ ] Add topic decomposition logic inline (move from coordinator to command)
  - [ ] Add report path pre-calculation inline (move from coordinator to command)
  - [ ] Generate `**EXECUTE NOW**: USE the Task tool...` directive for EACH topic
  - [ ] Create Task block per topic with concrete values (not bash variables)
  - [ ] Use bash loop to generate multiple Task invocation blocks if needed
- [ ] Update state machine transitions to remove coordinator-specific states
- [ ] Update error handling to parse research-specialist errors directly
- [ ] Test command with 1, 3, and 5 topics to verify all Task invocations execute

**Success Criteria**:
- [ ] Command contains NO Task invocations to research-coordinator
- [ ] Command contains N Task invocations to research-specialist (where N = topic count)
- [ ] Each Task invocation has `**EXECUTE NOW**` imperative directive
- [ ] Task blocks use concrete values (not placeholders like `${TOPICS[0]}`)
- [ ] All research reports created successfully
- [ ] Command passes validation: `bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/research.md`

**Dependencies**: Phase 1 (coordinator refactor complete)

**Estimated Hours**: 2-3 hours

---

### Phase 3: Refactor /create-plan Command for Direct Invocation [NOT STARTED]

**Objective**: Modify `/create-plan` command to invoke research-specialist agents directly when complexity >= 3 (research-and-plan workflow).

**Tasks**:
- [ ] Read current `/create-plan` command implementation (`.claude/commands/create-plan.md`)
- [ ] Identify research-coordinator invocation blocks (complexity >= 3 branch)
- [ ] Replace coordinator invocation with direct research-specialist invocations:
  - [ ] Add topic decomposition logic for multi-topic research scenarios
  - [ ] Pre-calculate report paths using `create_topic_artifact()` utility
  - [ ] Generate Task invocation block for EACH research topic
  - [ ] Ensure imperative directives precede each Task block
- [ ] Update plan-architect invocation to include ALL research report paths
- [ ] Update error handling for research-specialist failures
- [ ] Test command with complexity 3 and 4 scenarios (multi-topic research)

**Success Criteria**:
- [ ] Command invokes research-specialist directly (no coordinator layer)
- [ ] Research metadata aggregation handled by command (not coordinator)
- [ ] Plan-architect receives complete list of research report paths
- [ ] Command passes Task invocation validation
- [ ] End-to-end test: `/create-plan "Fix authentication timeout" --complexity 3` succeeds

**Dependencies**: Phase 2 (research command refactor complete)

**Estimated Hours**: 2-3 hours

---

### Phase 4: Refactor /lean-plan Command for Direct Invocation [NOT STARTED]

**Objective**: Modify `/lean-plan` command to invoke research-specialist agents directly for Lean-specific research topics (Mathlib, Proofs, Structure, Style).

**Tasks**:
- [ ] Read current `/lean-plan` command implementation (`.claude/commands/lean-plan.md`)
- [ ] Identify research-coordinator invocation blocks (Lean research phase)
- [ ] Replace coordinator invocation with direct research-specialist invocations:
  - [ ] Inline Lean-specific topic list (Mathlib theorems, Proof automation, Project structure, Lean style guide)
  - [ ] Pre-calculate report paths for each Lean topic
  - [ ] Generate Task invocation for each topic with Lean-specific context
  - [ ] Ensure Lean research context preserved in each invocation
- [ ] Update lean-plan-architect invocation to include research report paths
- [ ] Test command with Lean projects requiring all 4 research topics

**Success Criteria**:
- [ ] Command invokes research-specialist directly for each Lean topic
- [ ] All 4 Lean research reports created successfully
- [ ] lean-plan-architect receives complete research context
- [ ] Command passes Task invocation validation
- [ ] End-to-end test: `/lean-plan "Prove Fermat's Last Theorem case" --complexity 3` succeeds

**Dependencies**: Phase 3 (create-plan command refactor complete)

**Estimated Hours**: 2-3 hours

---

### Phase 5: Update Documentation and Validation [NOT STARTED]

**Objective**: Update hierarchical agent documentation to clarify Task tool constraints, add validation for agent allowed-tools correctness, and remove invalid supervisor patterns.

**Tasks**:
- [ ] Update `.claude/docs/concepts/hierarchical-agents-overview.md`:
  - [ ] Add Task tool constraint section (lines 74-80): Only primary agents can invoke Task tool
  - [ ] Clarify supervisor limitations (agents invoked via Task cannot use Task)
  - [ ] Update communication flow diagram to show primary agent → workers (no supervisor Task layer)
- [ ] Update `.claude/docs/concepts/hierarchical-agents-examples.md`:
  - [ ] Review Example 2 (supervisor pattern) for Task tool violations
  - [ ] Correct or remove examples showing agents invoking Task tool
  - [ ] Add Example 9: "Invalid Pattern - Agent Using Task Tool" (anti-pattern documentation)
- [ ] Create validation script `.claude/scripts/lint-agent-allowed-tools.sh`:
  - [ ] Parse agent frontmatter for `allowed-tools` field
  - [ ] Check if `Task` appears in agent allowed-tools (agents should NOT have Task)
  - [ ] Check if `Task` appears in command allowed-tools (commands CAN have Task)
  - [ ] Generate ERROR for agents with Task in allowed-tools
- [ ] Integrate new linter into `.claude/scripts/validate-all-standards.sh`
- [ ] Add pre-commit hook integration for agent allowed-tools validation

**Success Criteria**:
- [ ] hierarchical-agents-overview.md explicitly documents Task tool constraint
- [ ] hierarchical-agents-examples.md contains no invalid supervisor patterns
- [ ] New linter detects Task in agent allowed-tools: `bash .claude/scripts/lint-agent-allowed-tools.sh .claude/agents/*.md`
- [ ] Validation script integrated into `validate-all-standards.sh --agents` category
- [ ] Pre-commit hook blocks commits with agent Task tool violations
- [ ] All existing agents pass validation (no Task in allowed-tools except where appropriate)

**Dependencies**: Phases 1-4 (all command refactors complete)

**Estimated Hours**: 2-3 hours

---

## Testing Strategy

### Unit Tests

**Phase 1 (Coordinator Refactor)**:
- [ ] Test research-coordinator returns invocation plan (not reports)
- [ ] Verify invocation plan contains correct topic count and report paths
- [ ] Validate STEP 4 checks invocation plan file (not report files)

**Phases 2-4 (Command Refactors)**:
- [ ] Test each command with 1, 3, 5 topics (verify all Task invocations execute)
- [ ] Test Task invocation pattern validation passes: `lint-task-invocation-pattern.sh`
- [ ] Verify each command creates expected number of research reports

**Phase 5 (Validation)**:
- [ ] Test agent allowed-tools linter detects Task in agent files
- [ ] Verify linter allows Task in command files
- [ ] Run full standards validation: `bash .claude/scripts/validate-all-standards.sh --all`

### Integration Tests

- [ ] End-to-end test: `/research "Authentication patterns and error handling"`
  - Verify: 2 research reports created, no coordinator invocation, research-specialist invoked directly
- [ ] End-to-end test: `/create-plan "Implement JWT refresh tokens" --complexity 3`
  - Verify: Research phase completes, plan-architect receives all report paths, plan file created
- [ ] End-to-end test: `/lean-plan "Prove commutativity of addition" --complexity 3`
  - Verify: 4 Lean research reports created, lean-plan-architect receives all reports, plan includes Mathlib references

### Regression Tests

- [ ] Verify existing workflows unaffected:
  - [ ] `/create-plan` with complexity 1-2 (no research phase) still works
  - [ ] `/lean-plan` with complexity 1-2 (no research phase) still works
  - [ ] Other commands not using research-coordinator unaffected
- [ ] Verify pre-commit hooks don't break existing valid patterns

### Test Automation

- [ ] Create test script: `.claude/tests/commands/test_research_direct_invocation.sh`
  - Test /research with multiple topics
  - Verify report file creation
  - Validate Task invocation patterns
- [ ] Create test script: `.claude/tests/agents/test_agent_allowed_tools.sh`
  - Run lint-agent-allowed-tools.sh on all agents
  - Verify no false positives (commands with Task are allowed)
  - Verify no false negatives (agents with Task are detected)

**Test Coverage Target**: 95% (all critical paths, edge cases, and regression scenarios)

---

## Documentation Requirements

### Code Documentation

**Inline Comments**:
- [ ] Add comments to new topic decomposition logic in commands (explain what code does, not why)
- [ ] Document Task invocation generation patterns in commands
- [ ] Add checkpoint comments before each Task invocation block

**README Updates**:
- [ ] Update `.claude/commands/README.md` to document research workflow changes
- [ ] Update `.claude/agents/README.md` to clarify agent vs. command Task tool usage

### Reference Documentation

**Standards Updates**:
- [ ] Update `.claude/docs/reference/standards/command-authoring.md`:
  - Add section: "Agent Files Cannot Use Task Tool" (architectural constraint)
  - Add examples of correct primary agent → worker invocation patterns
  - Add anti-pattern: agents with Task in allowed-tools

**Guide Updates**:
- [ ] Update `.claude/docs/guides/commands/research-command-guide.md`:
  - Document new direct invocation pattern
  - Remove references to research-coordinator intermediary
  - Update workflow diagrams

### Architecture Documentation

**Hierarchical Agents**:
- [ ] Update `.claude/docs/concepts/hierarchical-agents-patterns.md`:
  - Document Task tool constraint pattern
  - Add pattern: "Primary Agent Direct Worker Invocation"
  - Remove or correct invalid supervisor patterns

**Migration Documentation**:
- [ ] Create `.claude/docs/guides/development/research-coordinator-deprecation-guide.md`:
  - Document reason for deprecation (architectural violation)
  - Provide migration examples for other commands using coordinator
  - Reference hierarchical-agents-examples.md Example 1 as correct pattern

---

## Risks and Mitigations

### Risk 1: Context Window Growth
**Description**: Removing coordinator's metadata aggregation layer increases context consumption from 330 tokens (metadata-only) to 7,500-10,000 tokens (full reports).

**Impact**: Medium - For 3-4 topics, context cost is acceptable within 200k window. For 5+ topics, may approach limits.

**Mitigation**:
- Accept trade-off for correctness (architectural compliance > optimization)
- Monitor context usage in production workflows
- Consider future enhancement: primary agent does metadata extraction (not coordinator)

### Risk 2: Command Complexity Increase
**Description**: Moving topic decomposition and path pre-calculation from coordinator to commands increases command file size and complexity.

**Impact**: Low - Logic is straightforward, well-documented in coordinator implementation.

**Mitigation**:
- Extract common logic to library functions in `.claude/lib/workflow/`
- Create reusable topic decomposition utility: `decompose_research_topics()`
- Document inline logic with clear comments

### Risk 3: Breaking Changes for Other Commands
**Description**: If other commands depend on research-coordinator (beyond /research, /create-plan, /lean-plan), refactor may break workflows.

**Impact**: Low - Research found only 3 commands use coordinator.

**Mitigation**:
- Search codebase for research-coordinator references: `grep -r "research-coordinator" .claude/`
- Update all commands found in search
- Add deprecation notice to research-coordinator.md frontmatter

### Risk 4: Validation False Positives
**Description**: New agent allowed-tools linter may incorrectly flag valid patterns as violations.

**Impact**: Low - Validation logic is straightforward (agents shouldn't have Task).

**Mitigation**:
- Thoroughly test linter against all existing agents and commands
- Add linter configuration for exceptions if needed (e.g., experimental agents)
- Include clear error messages explaining why Task in agent is invalid

---

## Success Metrics

### Functional Metrics
- [ ] 0 Task tool invocations in research-coordinator.md (down from 3-5)
- [ ] 100% success rate for direct research-specialist invocations in refactored commands
- [ ] 100% report file creation success rate (no empty reports directories)
- [ ] 0 validation errors from `lint-task-invocation-pattern.sh` on refactored commands

### Quality Metrics
- [ ] 0 agent files with Task in allowed-tools (down from 1)
- [ ] 100% test coverage for refactored command research phases
- [ ] 0 pre-commit hook failures for Task invocation patterns
- [ ] 100% documentation completeness (all affected docs updated)

### Performance Metrics
- [ ] Context usage increase measured: baseline vs. post-refactor (expected: +7,000-9,500 tokens for 3-topic research)
- [ ] Command execution time delta < 5% (refactor should not significantly impact performance)
- [ ] Research report generation time unchanged (no coordinator overhead removed)

---

## Rollback Plan

### Rollback Trigger Conditions
- Critical bug in refactored commands (research reports not created, Task invocations fail)
- Context window exhaustion in production workflows (5+ topics exceed 200k limit)
- Performance regression > 20% execution time increase

### Rollback Procedure
1. **Revert command files**: `git checkout HEAD~1 .claude/commands/research.md .claude/commands/create-plan.md .claude/commands/lean-plan.md`
2. **Restore research-coordinator.md**: `git checkout HEAD~1 .claude/agents/research-coordinator.md`
3. **Remove validation scripts**: `git rm .claude/scripts/lint-agent-allowed-tools.sh`
4. **Revert documentation**: `git checkout HEAD~1 .claude/docs/concepts/hierarchical-agents-*.md`
5. **Verify rollback**: Run end-to-end tests with coordinator pattern
6. **Document rollback reason**: Create issue in project tracker explaining why rollback occurred

### Post-Rollback Actions
- Analyze root cause of rollback trigger
- Design alternative solution addressing both correctness and performance
- Consider architectural changes (e.g., coordinator as library, not agent)

---

## Notes

**Standards Compliance**:
- Plan follows Plan Metadata Standard (required fields present, validation rules satisfied)
- Implementation follows Command Authoring Standards (Task invocation patterns, imperative directives)
- Testing follows Testing Protocols (non-interactive tests, programmatic validation, artifact outputs)

**Architecture Rationale**:
- Option A (direct invocation) chosen over Option B (hybrid) and Option C (no coordinator) because:
  - Simplest standards-compliant pattern (matches Example 1)
  - Clearest separation of concerns (commands orchestrate, agents execute)
  - No ambiguous agent responsibilities (agents don't coordinate other agents via Task)

**Future Enhancements** (out of scope):
- Extract topic decomposition to reusable library function
- Implement primary agent metadata extraction (recover 95% context reduction without coordinator)
- Explore alternative coordination patterns (coordinator as Bash library, not agent)

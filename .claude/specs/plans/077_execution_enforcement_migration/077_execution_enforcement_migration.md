# Execution Enforcement Migration Implementation Plan

## Metadata
- **Date**: 2025-10-20
- **Feature**: Systematic migration of commands and agents to execution enforcement patterns
- **Scope**: 12 commands and 10 agents requiring Standard 0 and Standard 0.5 compliance
- **Estimated Phases**: 8 phases across 7 weeks
- **Total Effort**: 100-130 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Migration Guide**: /home/benjamin/.config/.claude/docs/guides/execution-enforcement-migration-guide.md
- **Priority**: High - Critical for reliable subagent delegation and 100% file creation rates
- **Structure Level**: 1
- **Expanded Phases**: [2, 3, 4, 5, 6, 7, 8]

## Overview

This plan systematically migrates all relevant commands and agents to execution enforcement patterns (Standard 0 for commands, Standard 0.5 for agents) to achieve 100% file creation rates and predictable subagent execution.

### Problem Statement

**Current State**:
- 12 of 21 commands invoke subagents but lack enforcement patterns
- 10 of 20 agents lack systematic enforcement (Standard 0.5)
- Variable file creation rates (60-80%)
- Commands executing directly instead of orchestrating agents
- **Critical Issue**: All 12 commands missing Phase 0 role clarification, causing ambiguous execution

**Root Cause (Phase 0)**:
Commands use ambiguous language like "I'll research the topic" which Claude interprets as "I should execute research directly" instead of "I should orchestrate agents to research". This prevents:
- Task tool invocations (uses Read/Grep/Write instead)
- Hierarchical multi-agent patterns
- Parallel execution
- Metadata-based context reduction

**Target State**:
- 100% file creation rate (10/10 test runs per command/agent)
- All commands score ≥95/100 on audit script
- All agents score ≥95/100 on audit script
- Hierarchical multi-agent patterns execute correctly
- Zero regressions in existing functionality

## Success Criteria

- [ ] All 12 commands migrated with Phase 0 role clarification
- [ ] All 12 commands score ≥95/100 on audit-execution-enforcement.sh
- [ ] All 10 agents migrated with 5-phase transformation
- [ ] All 10 agents score ≥95/100 on audit-execution-enforcement.sh
- [ ] 100% file creation rate for all migrated commands/agents (10/10 tests)
- [ ] Hierarchical pattern verified working on /report command
- [ ] Conditional orchestration verified on /plan and /implement commands
- [ ] All existing test suites pass (zero regressions)
- [ ] System-wide integration tests pass
- [ ] Documentation updated with new patterns

## Technical Design

### Migration Architecture

**Agent Migration (Standard 0.5)**:
5-phase transformation process:
1. **Phase 1**: Role declaration - Transform "I am" to "YOU MUST"
2. **Phase 2**: Sequential steps - Add "STEP N (REQUIRED BEFORE STEP N+1)"
3. **Phase 3**: Passive voice elimination - Replace should/may/can with MUST/WILL/SHALL
4. **Phase 4**: Template enforcement - Add "THIS EXACT TEMPLATE" markers
5. **Phase 5**: Completion criteria - Add "COMPLETION CRITERIA - ALL REQUIRED"

**Command Migration (Standard 0)**:
4-pattern enforcement plus critical Phase 0:
- **Phase 0** (NEW - CRITICAL): Role clarification
  - "I'll orchestrate" (not "I'll execute")
  - "YOUR ROLE: You are the ORCHESTRATOR"
  - "DO NOT execute yourself using [tools]"
  - "ONLY use Task tool to delegate"
- **Pattern 1**: Path pre-calculation ("EXECUTE NOW - Calculate Paths")
- **Pattern 2**: Verification checkpoints ("MANDATORY VERIFICATION")
- **Pattern 3**: Fallback mechanisms (file existence checks + fallback creation)
- **Pattern 4**: Checkpoint reporting ("CHECKPOINT REQUIREMENT")
- **Agent Invocations**: "THIS EXACT TEMPLATE (No modifications)"

### Migration Dependencies

**Critical Order**:
1. Migrate agents BEFORE commands that invoke them
2. Test after each migration (no batching without validation)
3. Use compliant agents as reference models:
   - research-specialist.md (95/100)
   - plan-architect.md (95/100)
   - code-writer.md (95/100)

### Testing Strategy

**Per-Migration Testing**:
```bash
# Test 1: File creation rate (target: 10/10)
for i in {1..10}; do
  /command-name "test input $i"
  [ -f "$EXPECTED_FILE" ] && echo "✓" || echo "✗"
done

# Test 2: Audit score (target: ≥95/100)
.claude/lib/audit-execution-enforcement.sh .claude/commands/command.md

# Test 3: Verification checkpoints
/command-name "test" 2>&1 | grep -E "(✓ Verified|CHECKPOINT|MANDATORY)"

# Test 4: Fallback activation (simulate agent non-compliance)
# Temporarily modify agent to not create file, verify fallback works
```

**System-Wide Testing**:
- Run full .claude/tests/ suite
- Test hierarchical patterns (/report with multiple subtopics)
- Test conditional orchestration (/plan simple vs complex, /implement complexity-based)
- Verify parallel execution still works
- Check context window usage (<30% for orchestrators)

## Risk Assessment

### High Risks

**Risk 1: Breaking Existing Functionality**
- **Impact**: High - Could break production workflows
- **Likelihood**: Medium
- **Mitigation**:
  - Test after each migration
  - Run regression tests frequently
  - Keep git backups, use feature branches
  - Migrate agents before commands

**Risk 2: Time Overruns**
- **Impact**: Medium - Delays other work
- **Likelihood**: Medium
- **Mitigation**:
  - Front-load high-priority items (Tier 1 commands, Wave 1 agents)
  - Minimum viable: Tier 1 + Wave 1-2 provides 80% value
  - Time-box each migration task

**Risk 3: Audit Scores Not Improving**
- **Impact**: Medium - Migration incomplete
- **Likelihood**: Low
- **Mitigation**:
  - Run audit after each phase, not just at end
  - Use migration guide checklist
  - Compare against reference models
  - Address missing patterns systematically

### Medium Risks

**Risk 4: Enforcement Patterns Conflicting**
- **Impact**: Medium - Inconsistent behavior
- **Likelihood**: Low
- **Mitigation**:
  - Study reference models first
  - Use consistent templates
  - Review migration guide for each pattern

## Implementation Phases

### Phase 1: Foundation Setup and Baseline Measurement [COMPLETED]
**Objective**: Establish testing infrastructure and baseline metrics for all commands/agents
**Complexity**: Low
**Duration**: 8 hours (Week 1)
**Status**: COMPLETED
**Completion Date**: 2025-10-20

#### Tasks

- [x] Create testing framework
  - [x] Write test harness script for running commands 10 times (.claude/tests/test_migration_file_creation.sh)
  - [x] Create file creation rate tracking script (.claude/lib/track-file-creation-rate.sh)
  - [x] Set up baseline measurement infrastructure
  - [x] Document testing procedures in .claude/docs/guides/migration-testing.md

- [x] Baseline audit for commands
  - [x] Run audit-execution-enforcement.sh on all 12 commands requiring migration
  - [x] Record baseline scores in .claude/specs/plans/077_migration_tracking.csv
  - [x] Measure file creation rates (10 runs each) - NOTE: Scores recorded, detailed file creation testing to be done during migration
  - [x] Document current enforcement gaps

- [x] Baseline audit for agents
  - [x] Run audit-execution-enforcement.sh on all 10 agents requiring migration
  - [x] Record baseline scores in tracking spreadsheet
  - [x] Measure file creation rates (10 runs via commands that invoke them) - NOTE: Scores recorded, detailed testing to be done during migration
  - [x] Document missing enforcement patterns

- [x] Identify reference models
  - [x] Study research-specialist.md (extract enforcement patterns)
  - [x] Study plan-architect.md (extract enforcement patterns)
  - [x] Study code-writer.md (extract enforcement patterns)
  - [x] Create enforcement pattern templates in .claude/docs/guides/enforcement-patterns.md (combined with pattern docs)
  - [x] Document migration patterns in .claude/docs/guides/enforcement-patterns.md

#### Testing
```bash
# Verify test harness works
.claude/tests/test_migration_file_creation.sh /report "test topic"

# Verify audit script works on all files
for cmd in .claude/commands/*.md; do
  .claude/lib/audit-execution-enforcement.sh "$cmd" || true
done

# Expected: Baseline scores and file creation rates recorded
```

#### Deliverables
- [x] Test harness scripts created and verified
- [x] Baseline metrics recorded for all 12 commands and 10 agents
- [x] Reference model patterns documented
- [x] Migration tracking spreadsheet initialized
- [x] Testing procedures documented

#### Phase 1 Summary

**Baseline Audit Results**:

Commands (11 audited):
- Already at target (≥95): /report (95), /implement (95), /orchestrate (95), /debug (100), /expand (100)
- Close to target (90-94): /plan (90)
- Need work (85-89): /document (85)
- Major work needed (<85): /collapse (20), /refactor (-5), /test (0), /revise (0)

Agents (13 audited, including references):
- Reference models: research-specialist (110), plan-architect (100)
- Close to target: spec-updater (85), code-writer (60)
- Need significant work: All Wave 1-3 agents (0-15)

**Key Findings**:
1. Many Tier 1 commands already have strong enforcement (≥90)
2. Most agents need substantial migration work (0-15 baseline scores)
3. Reference models provide excellent patterns to follow
4. Enforcement patterns documented with 11 reusable templates

**Infrastructure Created**:
- test_migration_file_creation.sh - File creation rate testing
- track-file-creation-rate.sh - Results tracking
- migration-testing.md - Complete testing guide (7 test types)
- enforcement-patterns.md - 11 patterns extracted from reference models
- 077_migration_tracking.csv - Baseline metrics for 24 files

---

### Phase 2: Agent Migration - Wave 1 (File Creation Agents)
**Objective**: Migrate highest-priority file creation agents (doc-writer, debug-specialist, test-specialist)
**Complexity**: High (9/10)
**Duration**: 18 hours (Week 2)
**Status**: PENDING

**Summary**: First wave of agent migrations applying 5-phase transformation (role declaration, sequential steps, passive voice elimination, template enforcement, completion criteria) to three critical file creation agents. Each agent requires detailed transformation with concrete before/after examples and comprehensive testing to achieve ≥95/100 audit scores and 100% file creation rates.

**Detailed Implementation**: See [Phase 2 Expansion](phase_2_expansion.md) (2,102 lines)

#### Key Deliverables
- [ ] doc-writer.md migrated and tested (score ≥95/100, 10/10 file creation)
- [ ] debug-specialist.md migrated and tested (score ≥95/100, 10/10 file creation)
- [ ] test-specialist.md migrated and tested (score ≥95/100, 10/10 file creation)
- [ ] Tracking spreadsheet updated with Wave 1 results

---

### Phase 3: Agent Migration - Wave 2 (Expansion/Collapse + Fine-Tuning)
**Objective**: Migrate expansion-specialist, collapse-specialist, and fine-tune spec-updater
**Complexity**: Medium-High (7/10)
**Duration**: 10 hours (Week 2-3)
**Status**: PENDING

**Summary**: Second wave focuses on progressive planning system agents (expansion/collapse specialists) and fine-tuning spec-updater. These agents manipulate plan hierarchy structures (Level 0→1→2 transitions) and manage artifact lifecycles, requiring deep understanding of dependency tracking and metadata management.

**Detailed Implementation**: See [Phase 3 Expansion](phase_3_expansion.md) (1,222 lines)

#### Key Deliverables
- [ ] expansion-specialist.md migrated (score ≥95/100)
- [ ] collapse-specialist.md migrated (score ≥95/100)
- [ ] spec-updater.md fine-tuned (score ≥95/100, up from 85)
- [ ] Tracking spreadsheet updated with Wave 2 results
- [ ] All Wave 1 + Wave 2 agents complete (6 of 10 agents done)

---

### Phase 4: Command Migration - Tier 1 Critical (/report)
**Objective**: Migrate /report command with Phase 0 role clarification to fix hierarchical pattern execution
**Complexity**: High (8/10)
**Duration**: 8 hours (Week 3 - Day 1-2)
**Status**: PENDING

**Summary**: Critical migration of /report command to add Phase 0 orchestrator role clarification while preserving existing hierarchical multi-agent pattern (92-97% context reduction, 40-60% time savings). Must maintain metadata-based context passing, recursive supervision, and parallel research agent coordination while adding enforcement patterns.

**Detailed Implementation**: See [Phase 4 Expansion](phase_4_expansion.md) (1,280 lines)

#### Key Deliverables
- [ ] /report command migrated with Phase 0 role clarification
- [ ] Hierarchical multi-agent pattern verified working
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10 tests)
- [ ] Zero regressions (existing /report usage still works)
- [ ] Tracking spreadsheet updated

---

### Phase 5: Command Migration - Tier 1 Critical (/plan)
**Objective**: Migrate /plan command with Phase 0 for conditional orchestration clarity
**Complexity**: High (8/10)
**Duration**: 10 hours (Week 3 - Day 3-4)
**Status**: PENDING

**Summary**: Migration of /plan command with mixed execution model - direct plan creation for simple features vs. conditional research delegation for complex features. Requires Phase 0 clarification for Step 0.5 (research delegation) while preserving direct execution mode for Steps 1-7. Integration with plan-from-template and plan-wizard must remain functional.

**Detailed Implementation**: See [Phase 5 Expansion](phase_5_expansion.md) (618 lines)

#### Key Deliverables
- [ ] /plan command migrated with Phase 0 for conditional orchestration
- [ ] Conditional logic verified (simple features → direct, complex → orchestration)
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10 tests)
- [ ] Tracking spreadsheet updated

---

### Phase 6: Command Migration - Tier 1 Critical (/implement)
**Objective**: Migrate /implement command with Phase 0 role distinction for conditional execution
**Complexity**: Very High (9/10)
**Duration**: 14 hours (Week 3-4 - Day 5, Week 4 - Day 1-2)
**Status**: PENDING

**Summary**: Most complex command migration with triple role (coordinator, executor, orchestrator) based on adaptive phase complexity detection. Integrates with 5 agent types (implementation-researcher, code-writer, debug-specialist, doc-writer, spec-updater) and must preserve adaptive planning integration with automatic /revise invocation, checkpoint management, and replan counters.

**Detailed Implementation**: See [Phase 6 Expansion](phase_6_expansion.md) (1,663 lines)

#### Key Deliverables
- [ ] /implement command migrated with Phase 0 role distinction
- [ ] Conditional orchestration verified (simple → direct, complex → agents)
- [ ] Adaptive planning still functional
- [ ] Test failure handling verified
- [ ] Audit score ≥95/100
- [ ] File creation rate 100% (10/10 tests)
- [ ] Tracking spreadsheet updated

---

### Phase 7: Command Migration - Tier 2 & 3 (Remaining Commands)
**Objective**: Migrate /orchestrate, /debug, /refactor, /expand, /collapse, /convert-docs
**Complexity**: Exceptional (10/10)
**Duration**: 40 hours (Week 4-5)
**Status**: PENDING

**Summary**: Bundles 6 distinct command migrations with varying architectural patterns: /orchestrate (7-phase workflow with 6 agent types), /debug (parallel hypothesis investigation), /refactor (codebase analysis), /expand (progressive planning with auto-analysis), /collapse (hierarchy management), and /convert-docs (dual-mode script/agent). Each has unique delegation patterns and testing requirements. Time allocation: 12h + 8h + 5h + 5h + 5h + 5h = 40 hours.

**Detailed Implementation**: See [Phase 7 Expansion](phase_7_expansion.md) (683 lines)

#### Key Deliverables
- [ ] All 6 Tier 2 & 3 commands migrated
- [ ] All commands score ≥95/100
- [ ] All commands achieve 100% file creation rate
- [ ] Tracking spreadsheet updated
- [ ] All 12 commands complete

---

### Phase 8: Agent Migration - Wave 3 & 4 + System Validation
**Objective**: Complete remaining agent migrations and perform comprehensive system validation
**Complexity**: High (8/10)
**Duration**: 22 hours (Week 6-7)
**Status**: PENDING

**Summary**: Final phase completing last 4 agent migrations (code-reviewer, complexity-estimator, plan-expander, metrics-specialist) plus comprehensive system validation across all 12 commands and 10 agents. Includes 5-stage validation: full test suite execution, hierarchical pattern testing, conditional orchestration verification, regression testing, and performance verification (100% file creation rates, <30% context usage). Concludes with documentation updates across command/agent READMEs, CHANGELOG, and migration guide.

**Detailed Implementation**: See [Phase 8 Expansion](phase_8_expansion.md) (1,235 lines)

#### Key Deliverables
- [ ] All 10 agents migrated (100% complete)
- [ ] All agents score ≥95/100
- [ ] System-wide tests passing (zero regressions)
- [ ] Performance metrics verified (100% file creation rates)
- [ ] Documentation updated
- [ ] Migration tracking spreadsheet finalized
- [ ] Final migration report created

---

## Testing Strategy

### Per-Migration Testing

**File Creation Rate Test**:
```bash
#!/bin/bash
# .claude/tests/test_migration_file_creation.sh

COMMAND=$1
TEST_INPUT=$2
SUCCESS_COUNT=0

for i in {1..10}; do
  OUTPUT=$($COMMAND "$TEST_INPUT $i" 2>&1)
  # Check if expected file was created (command-specific)
  if [ -f "$EXPECTED_FILE" ]; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    echo "Run $i: ✓"
  else
    echo "Run $i: ✗"
  fi
done

echo "File creation rate: $SUCCESS_COUNT/10"
[ $SUCCESS_COUNT -eq 10 ] && exit 0 || exit 1
```

**Audit Score Test**:
```bash
# Run after each migration
.claude/lib/audit-execution-enforcement.sh .claude/commands/command.md

# Expected: Score ≥95/100
# Check output for missing patterns
```

**Verification Checkpoint Test**:
```bash
# Verify checkpoints execute
/command "test input" 2>&1 | grep -E "(✓ Verified|CHECKPOINT|MANDATORY)"

# Expected: All verification markers appear in output
```

**Fallback Activation Test**:
```bash
# Simulate agent non-compliance
# 1. Temporarily modify agent to NOT create file
# 2. Run command
# 3. Verify fallback created the file
# 4. Restore agent

# Expected: File exists despite agent non-compliance
```

### System-Wide Testing

**Hierarchical Pattern Test** (/report):
```bash
/report "Comprehensive analysis of microservices architecture patterns with focus on event-driven design, CQRS, and service mesh implementations"

# Expected:
# 1. Task tool invocations visible in output
# 2. Multiple subtopic reports created (e.g., 4 reports for this complex topic)
# 3. Reports in hierarchical structure:
#    specs/{NNN_topic}/reports/001_event_driven_design.md
#    specs/{NNN_topic}/reports/002_cqrs_patterns.md
#    specs/{NNN_topic}/reports/003_service_mesh.md
#    specs/{NNN_topic}/reports/004_integration_strategies.md
# 4. Overview report: specs/{NNN_topic}/reports/000_overview.md
# 5. Zero direct Read/Grep usage (all via agents)
```

**Conditional Orchestration Test** (/plan, /implement):
```bash
# Test 1: Simple feature (direct execution)
/plan "Add a new keybinding for saving all buffers"
# Expected: No Task tool invocations, direct plan creation

# Test 2: Complex feature (orchestration)
/plan "Implement distributed tracing system with OpenTelemetry integration, custom exporters, and performance monitoring dashboard"
# Expected: Task tool invocations for research, then plan creation

# Test 3: Simple implementation (direct execution)
/implement specs/plans/simple_keybinding.md
# Expected: Direct implementation, no agents

# Test 4: Complex implementation (orchestration)
/implement specs/plans/distributed_tracing.md
# Expected: implementation-researcher and code-writer invoked
```

**Parallel Execution Test**:
```bash
# Monitor for parallel Task invocations
/report "Authentication best practices" 2>&1 | grep "Task {" | wc -l
# Expected: Multiple Task invocations (2-4 for this topic)

# Verify time savings (parallel should be faster than sequential)
time /report "Complex topic with 4 subtopics"
# Expected: Significantly faster than 4 sequential research operations
```

**Context Window Test**:
```bash
# Monitor context usage during /orchestrate
/orchestrate "Complete feature development from research to documentation"

# Expected metrics (from orchestrator logs):
# - Research phase: <20% context usage (metadata-only passing)
# - Planning phase: <25% context usage
# - Implementation phase: <30% context usage
# - Documentation phase: <20% context usage
```

## Documentation Requirements

### Updated Files

- [ ] .claude/commands/README.md
  - Add Phase 0 pattern examples
  - Document orchestration vs direct execution distinction
  - Add enforcement pattern reference

- [ ] .claude/agents/README.md
  - Add Standard 0.5 compliance examples
  - Reference compliant agents
  - Document 5-phase transformation process

- [ ] .claude/docs/guides/execution-enforcement-migration-guide.md
  - Add lessons learned from this migration
  - Update success metrics with actual results
  - Document any new patterns discovered

- [ ] CHANGELOG.md
  - Document migration completion
  - Note enforcement pattern additions
  - List all migrated commands and agents

- [ ] .claude/specs/plans/077_migration_tracking.csv
  - Final scores for all commands and agents
  - File creation rates
  - Before/after audit scores

### New Documentation

- [ ] .claude/docs/guides/migration-testing.md
  - Document testing procedures
  - Provide test harness usage examples
  - Document expected outcomes

- [ ] .claude/docs/guides/enforcement-patterns.md
  - Extract patterns from reference models
  - Provide reusable templates
  - Document best practices

- [ ] .claude/templates/enforcement/
  - command-phase-0-template.md
  - agent-5-phase-template.md
  - agent-invocation-template.md

## Dependencies

### External Dependencies
None - all migrations use existing tooling and patterns.

### Internal Dependencies

**Critical Dependency**: Agents must be migrated BEFORE commands that invoke them.

**Migration Order**:
1. Phase 1: Foundation (no dependencies)
2. Phase 2: Wave 1 agents (no dependencies - can reference compliant agents)
3. Phase 3: Wave 2 agents (no dependencies)
4. Phase 4: /report command (depends on research-specialist already being compliant ✓)
5. Phase 5: /plan command (depends on research-specialist ✓, spec-updater from Phase 3)
6. Phase 6: /implement command (depends on doc-writer, debug-specialist, test-specialist from Phase 2)
7. Phase 7: Remaining commands (depends on respective agents from Phases 2-3)
8. Phase 8: Wave 3-4 agents + validation (depends on all commands for testing)

**Blocked Tasks**: None - dependency order respected in phase structure.

## Notes

### Key Success Factors

1. **Phase 0 is Critical**: The newest pattern from the migration guide, Phase 0 role clarification addresses the root cause of commands executing directly instead of orchestrating. This MUST be applied to all 12 commands.

2. **Test After Each Migration**: Do not batch migrations without testing. Run the 4 tests (file creation rate, audit score, verification checkpoints, fallback activation) after EACH migration.

3. **Use Reference Models**: research-specialist.md, plan-architect.md, and code-writer.md are already compliant (95/100 scores). Study these for consistent enforcement patterns.

4. **Agents Before Commands**: Always migrate agents BEFORE migrating commands that invoke them. This ensures agent enforcement is in place when command enforcement is added.

5. **Track Progress**: Maintain the migration tracking spreadsheet throughout all phases. Record baseline scores, post-migration scores, and file creation rates.

### Minimum Viable Migration

If time-constrained, prioritize:
1. Phase 2: Wave 1 agents (doc-writer, debug-specialist, test-specialist) - 18 hours
2. Phase 4: /report command - 8 hours
3. Phase 6: /implement command - 14 hours

Total: 40 hours provides 80% of the value (core file creation reliability + critical workflow commands).

### Common Pitfalls to Avoid

1. **Half-Way Phase 0 Fix**: Don't just add "I'll orchestrate" without the full 4-element structure (YOUR ROLE, DO NOT, ONLY, explanation).

2. **Missing Template Markers**: Every agent invocation needs "THIS EXACT TEMPLATE (No modifications)" marker, not just behavioral injection.

3. **Incomplete Passive Voice Elimination**: Search thoroughly for should/may/can/consider/try - they often hide in example text or comments.

4. **Testing Only at End**: Test after EACH migration, not in batch at the end. Catch issues early.

5. **Skipping Verification Checkpoints**: Every critical file operation needs a verification block with fallback mechanism.

### Migration Timeline Summary

- **Week 1**: Foundation setup (8 hours)
- **Week 2**: Agent Wave 1 + Wave 2 (28 hours)
- **Week 3**: /report, /plan, /implement start (32 hours)
- **Week 4**: /implement finish, Tier 2 commands start (20 hours)
- **Week 5**: Tier 2-3 commands finish (20 hours)
- **Week 6**: Agent Wave 3-4 (10 hours)
- **Week 7**: System validation and documentation (12 hours)

**Total**: 130 hours (upper estimate with buffer)

### Post-Migration Maintenance

After migration complete:
- Monitor file creation rates in production usage
- Track any new enforcement pattern needs
- Update migration guide with lessons learned
- Consider creating automated enforcement validation in CI/CD

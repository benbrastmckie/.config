# Three-Tier Agent Pattern Improvements Implementation Plan

## Metadata
- **Date**: 2025-12-08 (Revised)
- **Feature**: Extend three-tier agent pattern (orchestrator → coordinator → specialist) across all commands with centralized documentation, coordinator templates, and expanded skills catalog
- **Scope**: Implement 4 phases of improvements covering foundation documentation, coordinator expansion for testing/debug/repair workflows, skills extraction for research/planning/testing capabilities, and advanced capabilities including doc-analyzer skill, code-reviewer skill, and checkpoint format standardization
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 59-80 hours
- **Complexity Score**: 165.5
- **Structure Level**: 1
- **Expanded Phases**: [2, 3, 4]
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - Spec 013: Research-coordinator integration across ALL planning commands (COMPLETE - provides research-invocation standards)
  - Spec 016: Lean command coordinator optimization (COMPLETE - provides hard barrier pattern reference)
- **Research Reports**:
  - [Three-Tier Agent Improvements Analysis](../reports/001-three-tier-agent-improvements-analysis.md)
  - [Plan 019 Revision Analysis](../reports/002-revision-analysis.md)

## Overview

This plan implements systematic improvements to the .claude/ agent architecture based on comprehensive research findings from spec 015. The current system has strong foundational patterns with research-coordinator exemplifying the supervisor-based approach (95% context reduction, 40-60% time savings via parallelization), but opportunities exist for broader coordinator adoption, skills expansion, and documentation uniformity.

The plan addresses three key gaps:
1. **Limited Coordinator Adoption**: Only research workflows use full three-tier pattern; testing, debug, and repair workflows use direct agent invocation
2. **Minimal Skills Catalog**: Only 1 skill exists (document-converter) despite 5 high-priority candidates identified
3. **Documentation Uniformity**: Missing centralized three-tier pattern guide and coordinator template

Implementation follows the priority matrix from research: Foundation (Phase 1), Coordinator Expansion (Phase 2), Skills Expansion (Phase 3), and Advanced Capabilities (Phase 4).

## Research Summary

Key findings from research analysis:

**Current State**:
- Research-coordinator demonstrates exemplary supervisor pattern (635 lines, hard barrier enforcement, metadata-only passing)
- Implementer-coordinator already exists with wave-based parallel execution
- Test, debug, and repair commands use two-tier architecture (orchestrator → specialist, no coordinator intermediary)
- Only 1 skill exists in catalog despite reusable capability opportunities

**Industry Best Practices Alignment**:
- Metadata-only passing: 95% context reduction achieved in research-coordinator matches industry standard (Anthropic 2025)
- Coordinator-specialist pattern: Aligns with Microsoft Azure AI and Skywork AI multi-agent orchestration patterns (2025)
- Context compaction: Non-reversible compaction implemented (path + metadata returned, not full content)

**Optimization Opportunities**:
- 3 new coordinators needed (testing, debug, repair) to parallelize currently sequential workflows
- 5 high-priority skills candidates: research-specialist, plan-generator, test-orchestrator, doc-analyzer, code-reviewer
- Documentation gaps: three-tier pattern guide, coordinator template, skills migration guide
- Pattern standardization: hard barrier adoption, metadata-only passing, error return protocol, checkpoint format

**Expected Impact**:
- Time savings: 40-60% for parallelized workflows (testing, debug, repair)
- Context efficiency: 95% reduction via metadata aggregation (110 tokens vs 2,500 tokens)
- Development acceleration: Coordinator creation time reduced from 4-6 hours to 2-3 hours with template

## Success Criteria

- [ ] Three-tier pattern guide created with decision matrix and migration steps
- [ ] Coordinator template created based on research-coordinator structure
- [ ] All command cross-references validated and updated
- [ ] Testing-coordinator implemented with parallel test-specialist invocation
- [ ] Debug-coordinator implemented with parallel investigation vectors
- [ ] Repair-coordinator implemented with parallel error dimension analysis
- [ ] Research-specialist skill extracted with autonomous invocation
- [ ] Plan-generator skill extracted with reusable planning logic
- [ ] Test-orchestrator skill created with autonomous test enforcement
- [ ] Doc-analyzer skill created with documentation quality analysis
- [ ] Code-reviewer skill created with linting and security checks
- [ ] Checkpoint format v3.0 standardized across all commands

## Technical Design

### Architecture Overview

The three-tier pattern consists of:
1. **Orchestrator Layer** (slash commands): User-facing entry points, argument capture, workflow state management
2. **Coordinator Layer** (coordinator agents): Supervisor-based parallel orchestration, metadata aggregation, hard barrier enforcement
3. **Specialist Layer** (specialist agents): Deep domain expertise, comprehensive artifact generation, structured error return

### Pattern Components

**Hard Barrier Pattern** (enforced at coordinator layer):
1. Path pre-calculation using `create_topic_artifact()` utility
2. Parallel specialist invocation via Task tool
3. Artifact validation (fail-fast on missing files)
4. Metadata extraction (110 tokens per artifact)

**Metadata-Only Passing** (95% context reduction):
```markdown
Report Metadata Format:
- **Path**: /absolute/path/to/artifact.md
- **Title**: Artifact title
- **Key Counts**: Lines, sections, findings
- **Status**: [IN PROGRESS]
```

**Error Return Protocol** (structured error handling):
```bash
ERROR_CONTEXT: {
  "error_type": "validation_error|agent_error|file_error",
  "message": "Human-readable description",
  "details": {"key": "value"}
}

TASK_ERROR: error_type - Brief message
```

### Integration Points

**Phase 1 Foundation**:
- Three-tier pattern guide links from CLAUDE.md hierarchical agent section
- Coordinator template stored in `.claude/agents/templates/`
- Link validation updates command and agent cross-references

**Phase 2 Coordinators**:
- Testing-coordinator integrates with `/test` command (replace direct test-executor invocation)
- Debug-coordinator integrates with `/debug` command (replace direct debug-analyst invocation)
- Repair-coordinator integrates with `/repair` command (replace direct repair-analyst invocation)

**Phase 3 Skills**:
- Research-specialist skill enables autonomous research across all workflows
- Plan-generator skill reuses planning logic across `/create-plan`, `/repair`, `/debug`
- Test-orchestrator skill auto-triggers after implementation phases

**Phase 4 Advanced**:
- Doc-analyzer skill auto-triggers on doc file changes
- Code-reviewer skill auto-triggers after implementation
- Checkpoint v3.0 enables resume across command boundaries

### Standards Alignment

**Code Standards Compliance**:
- All bash blocks use three-tier sourcing pattern (Tier 1: state-persistence.sh, workflow-state-machine.sh, error-handling.sh)
- All coordinator agents include fail-fast handlers for library sourcing
- All error logging uses `log_command_error()` from error-handling.sh

**Agent Communication Protocol**:
- All coordinators return metadata-only context (not full artifact content)
- All specialists return structured error signals on failure
- All artifacts validated via hard barrier pattern before metadata extraction

**Documentation Standards**:
- All new documentation follows CommonMark specification
- All templates include usage examples with syntax highlighting
- All cross-references use relative paths from document location
- No historical commentary (clean-break development standard)

## Implementation Phases

### Phase 1: Foundation [COMPLETE]
dependencies: []

**Objective**: Establish centralized three-tier pattern documentation and coordinator template to accelerate future coordinator development and ensure pattern consistency

**Complexity**: Low

**Revision Notes**:
- **COMPLETE** (via Spec 013 Phase 5): Research-invocation standards documented with decision matrix for research patterns
- **COMPLETE** (via Spec 013 Phase 6): Command-authoring standards updated with coordinator invocation templates
- **COMPLETE** (via Spec 013 Phase 7): Cross-references validated and CLAUDE.md hierarchical agent section updated
- **STILL NEEDED**: General three-tier pattern guide (focus on testing/debug/repair, not research which is already documented)
- **STILL NEEDED**: Coordinator template based on research-coordinator.md structure

**Tasks**:
- [x] Create three-tier pattern guide at `/home/benjamin/.config/.claude/docs/concepts/three-tier-agent-pattern.md` (file: `.claude/docs/concepts/three-tier-agent-pattern.md`)
  - **NOTE**: Focus on testing/debug/repair patterns. Research patterns already documented in `.claude/docs/reference/standards/research-invocation-standards.md` (Spec 013)
  - [x] Document pattern definition: orchestrator → coordinator → specialist with metadata aggregation
  - [x] Document benefits: 40-60% time savings (parallelization), 95% context reduction (metadata-only passing)
  - [x] Create decision matrix: when to use 1-tier (simple), 2-tier (single specialist), 3-tier (multiple specialists) for testing/debug/repair domains
  - [x] Document implementation checklist for new three-tier workflows
  - [x] Create migration guide from two-tier to three-tier patterns with concrete examples
  - [x] Reference existing research-invocation-standards.md for research patterns
  - [x] Add cross-reference links from CLAUDE.md hierarchical agent section and command authoring standards
- [x] Create coordinator template at `/home/benjamin/.config/.claude/agents/templates/coordinator-template.md` (file: `.claude/agents/templates/coordinator-template.md`)
  - [x] Base template on research-coordinator.md structure (635 lines) - validated pattern from Spec 013
  - [x] Include input contract specification section (topics, report_dir, context)
  - [x] Include two-mode support template (automated decomposition vs manual pre-decomposition)
  - [x] Include topic decomposition logic template with complexity mapping
  - [x] Include path pre-calculation pattern (hard barrier enforcement - reference Spec 016 implementation)
  - [x] Include parallel specialist invocation template via Task tool
  - [x] Include hard barrier validation template (fail-fast on missing artifacts - reference Spec 016 implementation)
  - [x] Include metadata extraction utilities (title, counts, aggregation)
  - [x] Include error return protocol template (validation_error, agent_error, file_error)
  - [x] Define template variables: {{COORDINATOR_TYPE}}, {{SPECIALIST_TYPE}}, {{ARTIFACT_TYPE}}, {{METADATA_FIELDS}}
- [x] ~~Validate and fix cross-references~~ **COMPLETE** (Spec 013 Phase 7)
- [x] ~~Update CLAUDE.md hierarchical agent section~~ **COMPLETE** (Spec 013 Phase 7)
- [x] Update `.claude/agents/templates/README.md` to include coordinator template description (file: `.claude/agents/templates/README.md`)

**Testing**:
```bash
# Verify three-tier pattern guide exists and is well-formed
test -f .claude/docs/concepts/three-tier-agent-pattern.md
grep -q "## Decision Matrix" .claude/docs/concepts/three-tier-agent-pattern.md

# Verify coordinator template exists with all required sections
test -f .claude/agents/templates/coordinator-template.md
grep -q "{{COORDINATOR_TYPE}}" .claude/agents/templates/coordinator-template.md

# Verify templates README updated
grep -q "coordinator-template.md" .claude/agents/templates/README.md
```

**Expected Duration**: 3-5 hours (reduced from 5-8 hours due to completed work in Spec 013)

---

### Phase 2: Coordinator Expansion [COMPLETE]
dependencies: [1]

**Objective**: Implement testing-coordinator, debug-coordinator, and repair-coordinator to extend parallel orchestration pattern to testing, debug, and repair workflows

**Complexity**: Medium (Expanded)

**Revision Notes**:
- **Hard Barrier Pattern**: Reuse hard barrier pattern from Spec 016 (lean-implement Phase 3) - pre-calculate paths, validate artifacts, fail-fast
- **Research Coordination**: Debug-coordinator and repair-coordinator should coordinate with research-coordinator for research phases (Specs 013 Phases 10-11)
- **Dual Coordinator Pattern**: Commands can use BOTH coordinators in sequence: research-coordinator for multi-topic research → domain-specific coordinator for parallel execution
- **Example Flow** (/debug): Block 1: research-coordinator (multi-topic root cause analysis) → Block 2: debug-coordinator (parallel investigation vectors)
- **Reduced Estimate**: 10-15 hours (reduced from 12-18 hours due to reusable hard barrier pattern from Spec 016)

**Summary**: Implement 3 new coordinator agents (testing, debug, repair) with parallel specialist invocation and integrate each with corresponding commands.

For detailed tasks and implementation, see [Phase 2 Details](phase_2_coordinator_expansion.md)

**Expected Duration**: 10-15 hours (reduced from 12-18 hours)

---

### Phase 3: Skills Expansion [NOT STARTED]
dependencies: [1, 2]

**Objective**: Extract research-specialist, plan-generator, and test-orchestrator as autonomous skills to enable broader applicability and autonomous composition

**Complexity**: Medium-High (Expanded)

**Summary**: Extract 3 skills (research-specialist, plan-generator, test-orchestrator) with autonomous invocation detection and backward-compatible Task invocation paths.

For detailed tasks and implementation, see [Phase 3 Details](phase_3_skills_expansion.md)

**Expected Duration**: 20-26 hours

---

### Phase 4: Advanced Capabilities [NOT STARTED]
dependencies: [3]

**Objective**: Implement doc-analyzer and code-reviewer skills for autonomous quality enforcement, and standardize checkpoint format v3.0 for cross-command resumption

**Complexity**: High (Expanded)

**Summary**: Create 2 advanced skills (doc-analyzer, code-reviewer) with linting/security integration, implement checkpoint v3.0 schema with migration utility, and migrate 4 commands to new checkpoint format.

For detailed tasks and implementation, see [Phase 4 Details](phase_4_advanced_capabilities.md)

**Expected Duration**: 26-34 hours

---

## Testing Strategy

### Overall Testing Approach

**Unit Testing**:
- Each coordinator agent tested independently with mock specialist invocations
- Each skill tested independently with sample inputs
- Checkpoint utilities tested with unit tests for save/load/migrate functions

**Integration Testing**:
- End-to-end testing for each three-tier workflow (orchestrator → coordinator → specialist)
- Cross-command checkpoint resumption testing (save in one command, resume in another)
- Skills auto-invocation testing (verify autonomous triggers work)

**Validation Testing**:
- Link validation for all documentation cross-references
- Metadata validation for coordinator return formats
- Schema validation for checkpoint v3.0 format

### Phase-Specific Testing

**Phase 1 Testing**:
- Documentation structure validation (three-tier pattern guide, coordinator template)
- Link validation for all cross-references
- Template variables verification (coordinator template)

**Phase 2 Testing**:
- Coordinator invocation testing (testing-coordinator, debug-coordinator, repair-coordinator)
- Metadata return format validation
- Partial success mode testing (≥50% threshold)
- Command integration testing (verify `/test`, `/debug`, `/repair` use coordinators)

**Phase 3 Testing**:
- Skills auto-invocation testing (verify autonomous triggers)
- Backward compatibility testing (Task invocation path still works)
- Skills catalog verification (README.md updated)

**Phase 4 Testing**:
- Doc-analyzer validation (README structure, link checking)
- Code-reviewer validation (linting, complexity, security)
- Checkpoint v3.0 schema validation
- Cross-command resumption testing

### Coverage Requirements

**Minimum Coverage Targets**:
- Coordinator agents: 80% path coverage (all modes tested)
- Skills: 70% invocation coverage (autonomous and explicit paths)
- Checkpoint utilities: 90% function coverage (critical for state management)

### Test Commands

```bash
# Phase 1: Documentation validation
bash .claude/scripts/validate-links-quick.sh .claude/docs/concepts/three-tier-agent-pattern.md
bash .claude/scripts/validate-links-quick.sh .claude/agents/templates/coordinator-template.md

# Phase 2: Coordinator integration tests
# (manual Task invocation tests during implementation)

# Phase 3: Skills auto-invocation tests
# (manual autonomous trigger tests during implementation)

# Phase 4: Advanced capabilities tests
bash .claude/commands/doc-check.md .claude/docs/
bash .claude/commands/review.md .claude/lib/
bash .claude/lib/workflow/checkpoint-utils.sh --test-migration
```

## Documentation Requirements

### New Documentation Files

**Phase 1**:
- `.claude/docs/concepts/three-tier-agent-pattern.md` - Centralized three-tier pattern guide with decision matrix and migration steps
- `.claude/agents/templates/coordinator-template.md` - Reusable coordinator template based on research-coordinator structure

**Phase 2**:
- `.claude/agents/testing-coordinator.md` - Testing coordinator agent for parallel test execution
- `.claude/agents/debug-coordinator.md` - Debug coordinator agent for parallel investigation
- `.claude/agents/repair-coordinator.md` - Repair coordinator agent for parallel error analysis

**Phase 3**:
- `.claude/skills/research-specialist/SKILL.md` - Research specialist skill for autonomous research
- `.claude/skills/research-specialist/README.md` - Research specialist skill documentation
- `.claude/skills/plan-generator/SKILL.md` - Plan generator skill for reusable planning
- `.claude/skills/plan-generator/README.md` - Plan generator skill documentation
- `.claude/skills/test-orchestrator/SKILL.md` - Test orchestrator skill for autonomous testing
- `.claude/skills/test-orchestrator/README.md` - Test orchestrator skill documentation

**Phase 4**:
- `.claude/skills/doc-analyzer/SKILL.md` - Documentation analyzer skill for quality enforcement
- `.claude/skills/doc-analyzer/README.md` - Documentation analyzer skill documentation
- `.claude/skills/code-reviewer/SKILL.md` - Code reviewer skill for quality enforcement
- `.claude/skills/code-reviewer/README.md` - Code reviewer skill documentation
- `.claude/commands/doc-check.md` - Documentation quality check command
- `.claude/commands/review.md` - Code quality review command

### Documentation Updates

**CLAUDE.md Updates**:
- Update hierarchical agent architecture section to reference three-tier pattern guide
- Update skills architecture section to include all 5 new skills (research-specialist, plan-generator, test-orchestrator, doc-analyzer, code-reviewer)
- Update state-based orchestration section with checkpoint v3.0 format

**README.md Updates**:
- `.claude/agents/templates/README.md` - Add coordinator template description
- `.claude/skills/README.md` - Update skills catalog with 5 new skills
- `.claude/lib/workflow/README.md` - Document checkpoint v3.0 schema

**Command Documentation Updates**:
- `.claude/commands/test.md` - Update to reflect three-tier architecture with testing-coordinator
- `.claude/commands/debug.md` - Update to reflect three-tier architecture with debug-coordinator
- `.claude/commands/repair.md` - Update to reflect three-tier architecture with repair-coordinator
- `.claude/docs/reference/standards/command-reference.md` - Add `/doc-check` and `/review` commands

### Cross-Reference Updates

All documentation updates must maintain bidirectional linking:
- Three-tier pattern guide ← CLAUDE.md hierarchical agent section
- Coordinator template ← `.claude/agents/templates/README.md`
- New coordinators ← respective command documentation
- New skills ← `.claude/skills/README.md` and CLAUDE.md skills section

## Dependencies

### External Dependencies

**No external dependencies required**: All implementation uses existing .claude/ infrastructure (lib/, agents/, commands/, skills/, docs/).

### Internal Dependencies

**Library Dependencies**:
- `.claude/lib/core/error-handling.sh` - Error logging integration for all coordinators
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint management (Phase 4 extends this)
- `.claude/lib/core/unified-location-detection.sh` - Artifact path calculation for coordinators
- `.claude/lib/workflow/validation-utils.sh` - Validation utilities for coordinators

**Agent Dependencies**:
- Research-coordinator (existing) - Template source for new coordinators
- Implementer-coordinator (existing) - Reference implementation for wave-based execution
- Plan-architect (existing) - Source for plan-generator skill extraction

**Command Dependencies**:
- `/test` command (existing) - Integration point for testing-coordinator
- `/debug` command (existing) - Integration point for debug-coordinator
- `/repair` command (existing) - Integration point for repair-coordinator
- `/create-plan` command (existing) - Integration point for plan-generator skill

### Prerequisite Tasks

**Before Phase 1**:
- No prerequisites (foundation phase)

**Before Phase 2**:
- Phase 1 must be complete (coordinator template required)

**Before Phase 3**:
- Phases 1 and 2 must be complete (coordinator pattern established, commands ready for skill integration)

**Before Phase 4**:
- Phase 3 must be complete (skills infrastructure expanded and validated)

## Risk Analysis

### High-Risk Areas

**Coordinator Integration Breakage** (Phase 2):
- Risk: Replacing direct agent invocation with coordinator delegation could break existing command workflows
- Mitigation: Maintain backward compatibility by testing old invocation paths, implement feature flags for gradual rollout
- Rollback: Revert command changes to direct invocation if coordinator integration fails

**Skills Auto-Invocation Conflicts** (Phase 3):
- Risk: Autonomous skill invocation might conflict with explicit Task invocations or trigger unexpectedly
- Mitigation: Implement clear invocation detection logic, test both autonomous and explicit paths separately
- Rollback: Disable autonomous invocation, fall back to explicit Task invocation only

**Checkpoint Format Migration** (Phase 4):
- Risk: Migrating from v2.0 to v3.0 checkpoint format could break resumption for in-progress workflows
- Mitigation: Implement `migrate_checkpoint_v2_to_v3()` utility, test migration with real checkpoints, maintain v2.0 compatibility during transition
- Rollback: Support both v2.0 and v3.0 formats, allow graceful degradation to v2.0

### Medium-Risk Areas

**Documentation Accuracy** (Phase 1):
- Risk: Three-tier pattern guide might not accurately represent best practices or might become outdated
- Mitigation: Base guide on research-coordinator (proven pattern), include concrete examples, link to existing implementations
- Rollback: Mark guide as draft, iterate based on feedback from coordinator implementations

**Template Reusability** (Phase 1):
- Risk: Coordinator template might be too specific to research-coordinator or not flexible enough
- Mitigation: Define clear template variables ({{COORDINATOR_TYPE}}, {{SPECIALIST_TYPE}}), test template with all three new coordinators in Phase 2
- Rollback: Create coordinator-specific templates instead of single reusable template

### Low-Risk Areas

**Link Validation Updates** (Phase 1):
- Risk: Minimal risk; link validation is non-invasive
- Mitigation: Use existing validate-links-quick.sh script, test on subset before full run

**Skills README Updates** (Phase 3, Phase 4):
- Risk: Minimal risk; documentation-only changes
- Mitigation: Follow existing skills README structure, validate markdown syntax

## Notes

**Progressive Implementation**: Phases are designed to be implemented sequentially, with each phase building on previous work. However, Phase 2 tasks (coordinators) can be implemented in parallel once Phase 1 is complete.

**Backward Compatibility**: All changes maintain backward compatibility:
- Coordinator integration preserves direct invocation fallback
- Skills extraction maintains Task invocation path
- Checkpoint v3.0 supports v2.0 migration

**Performance Monitoring**: Track time savings and context reduction metrics after each phase:
- Phase 2: Measure 40-60% time savings for parallelized workflows
- Phase 3: Measure autonomous skill invocation frequency
- Phase 4: Measure cross-command resumption success rate

**Expansion Hint**: Complexity score is 165.5 (Tier 2 range: 50-200). If implementation complexity grows during Phase 3 or Phase 4, consider using `/expand` command to break phases into stage files for better organization.

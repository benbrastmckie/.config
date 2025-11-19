# Implementation Plan: Improve optimize-claude.md Command to Meet All Standards

## Metadata
- **Date**: 2025-11-16
- **Feature**: Research the optimize-claude.md command in order to determine if there are any discrepancies or inconsistencies with the standards provided in .claude/docs/, creating a plan to improve the command to meet all standards
- **Scope**: Refactor and enhance optimize-claude.md command to achieve full compliance with project standards
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10 hours
- **Structure Level**: 0
- **Complexity Score**: 7/10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - 001: Analysis of optimize-claude.md command structure and implementation
  - 002: Comparison with .claude/docs/ standards and patterns
  - 003: Identification of discrepancies and inconsistencies

## Overview

This plan addresses the systematic improvement of the `/optimize-claude` command to achieve full compliance with project standards documented in `.claude/docs/`. Based on comprehensive research (3 reports, 86KB total), 19 discrepancies have been identified across critical, high, medium, and low priority levels. The command currently achieves ~65-75% standards compliance and has a production readiness score of ~45%. This implementation will bring compliance to 90-95% and production readiness to 95-100%.

### Key Problems Identified

**Critical Issues (10)**:
1. Missing orchestrator role clarification (Standard 0)
2. Inadequate imperative language enforcement (Standard 0.5)
3. Missing Phase 0 execution enforcement structure
4. Incomplete behavioral injection pattern implementation (Standard 12)
5. Missing EXECUTE NOW enforcement markers
6. Missing MANDATORY VERIFICATION checkpoints
7. No fallback mechanisms for agent failures
8. Inadequate path validation (only null checks)
9. No progress streaming markers
10. Weak return format specification for agents

**High Priority Issues (5)**:
- Behavioral injection clarity gaps
- Insufficient path validation depth
- Library integration documentation missing
- Phase dependencies not formalized
- Task tool syntax needs clarification

**Medium/Low Priority Issues (4)**:
- Library availability checking
- Structured completion checkpoints
- Context budget documentation
- Section formatting consistency

### Research Summary

Three comprehensive research reports provide detailed analysis:

1. **Command Structure Analysis (Report 001)**: 19KB report documenting multi-stage workflow architecture, agent specialization patterns, task-based invocation methods, parallel execution structure, and verification checkpoints. Identified 10 key architectural patterns and implementation approaches.

2. **Standards Comparison (Report 002)**: 27KB report analyzing compliance against 6 major standards, 11 enforcement patterns, and 12+ documentation files. Current compliance: 65-75%, with specific gaps in imperative language (65-70% compliance), behavioral injection (not documented), and verification consistency.

3. **Discrepancies Identification (Report 003)**: 38KB report cataloging 19 specific issues with severity levels, line-by-line analysis, code examples, and standards references. Provides detailed remediation guidance for each issue.

## Success Criteria

- [ ] All critical issues (10) resolved
- [ ] All high priority issues (5) resolved
- [ ] Medium/low priority issues addressed (at least 75%)
- [ ] Standards compliance score ≥90%
- [ ] Production readiness score ≥95%
- [ ] Command passes validation against execution enforcement guide
- [ ] All agent invocations use proper behavioral injection
- [ ] Imperative language enforcement throughout (100% MUST/SHALL/WILL)
- [ ] Comprehensive verification checkpoints with MANDATORY markers
- [ ] Fallback mechanisms implemented for all agent operations
- [ ] Path validation includes parent directory, absolute path, and writability checks
- [ ] Progress streaming implemented for user visibility
- [ ] Documentation updated to reference architectural patterns
- [ ] Command listed in command-reference.md
- [ ] Tests created for critical paths

## Implementation Phases

### Phase 1: Add Phase 0 - Orchestrator Role Clarification and Execution Enforcement

**Objective**: Implement missing Phase 0 structure with explicit orchestrator role declaration and execution enforcement foundation

**Duration**: 1.5-2 hours

**Tasks**:
- [ ] Add Phase 0 header section before current Phase 1
- [ ] Insert "YOU ARE EXECUTING as the orchestrator" declaration
- [ ] Add explicit role clarification: "You will ORCHESTRATE, not execute directly"
- [ ] List allowed orchestration tools (Task, workflow state management)
- [ ] List prohibited direct execution tools (Read, Grep, Write for analysis)
- [ ] Add source library loading with verification
- [ ] Implement fail-fast library availability checking
- [ ] Add progress streaming PROGRESS markers
- [ ] Document phase dependencies in header

**Dependencies**: None (foundational phase)

**Verification**:
- [ ] Phase 0 section exists with clear orchestrator role
- [ ] All required libraries sourced with error handling
- [ ] Role declaration uses imperative MUST language
- [ ] Tool allowlists clearly specified

**Standards Reference**:
- Standard 0: Execution Enforcement
- Standard 0.5: Agent Execution Enforcement
- Execution Enforcement Guide §2.1: Phase 0 Implementation

---

### Phase 2: Imperative Language Conversion

**Objective**: Convert all descriptive language to mandatory imperative directives (MUST, SHALL, WILL)

**Duration**: 2-3 hours

**Tasks**:
- [ ] Audit entire command file for passive/descriptive language
- [ ] Convert phase headers to imperative STEP format
- [ ] Replace "should", "may", "can" with "MUST", "SHALL", "WILL"
- [ ] Add EXECUTE NOW markers before all agent invocations
- [ ] Add CRITICAL markers for mandatory operations
- [ ] Update agent prompts to use imperative language
- [ ] Convert verification checkpoints to MANDATORY VERIFICATION format
- [ ] Review and strengthen all enforcement language
- [ ] Ensure consistency with execution enforcement guide patterns

**Dependencies**: Phase 1 (requires Phase 0 foundation)

**Verification**:
- [ ] Zero instances of "should", "may", "can" in command directives
- [ ] All phase headers use imperative STEP format
- [ ] All agent invocations preceded by EXECUTE NOW
- [ ] All verification checkpoints use MANDATORY language
- [ ] Command passes imperative language audit (100% compliance)

**Standards Reference**:
- Imperative Language Guide
- Execution Enforcement Guide §3: Language Requirements

---

### Phase 3: Behavioral Injection and Agent Invocation Improvements

**Objective**: Implement proper behavioral injection pattern separation and strengthen agent invocation clarity

**Duration**: 2-3 hours

**Tasks**:
- [ ] Separate agent behavioral guidelines from workflow context
- [ ] Reference agent behavioral files explicitly (Standard 12)
- [ ] Remove inline behavioral duplication
- [ ] Add proper AGENT_INVOCATION_MARKER comments
- [ ] Specify EXPECTED_OUTPUT paths before invocation
- [ ] Add CHECKPOINT REQUIREMENTS for agent returns
- [ ] Clarify Task tool syntax with examples
- [ ] Document agent specialization in comments
- [ ] Add agent return format specifications
- [ ] Implement context injection pattern correctly
- [ ] Add behavioral injection documentation references

**Dependencies**: Phase 2 (requires imperative language foundation)

**Verification**:
- [ ] All agent invocations reference behavioral files, not inline guidelines
- [ ] AGENT_INVOCATION_MARKER present for all Task calls
- [ ] EXPECTED_OUTPUT specified before each agent invocation
- [ ] Agent return formats specified as CHECKPOINT REQUIREMENTS
- [ ] No behavioral duplication in workflow file
- [ ] Standard 12 compliance achieved

**Standards Reference**:
- Standard 12: Behavioral Injection
- Agent Development Guide
- Execution Enforcement Guide §5: Agent Invocation

---

### Phase 4: Verification Checkpoints and Fallback Mechanisms

**Objective**: Implement comprehensive MANDATORY VERIFICATION checkpoints and graceful fallback mechanisms

**Duration**: 1.5-2 hours

**Tasks**:
- [ ] Add MANDATORY VERIFICATION markers to all checkpoints
- [ ] Enhance path validation with parent directory checks
- [ ] Add absolute path verification (Standard 13)
- [ ] Add writability validation for output paths
- [ ] Implement fallback artifact creation for agent failures
- [ ] Add graceful degradation for non-critical failures
- [ ] Create placeholder artifacts on agent timeout
- [ ] Add checkpoint abstraction function to reduce duplication
- [ ] Implement structured completion checkpoint
- [ ] Add resume capability for interrupted workflows
- [ ] Document verification requirements in comments

**Dependencies**: Phase 3 (requires proper agent structure)

**Verification**:
- [ ] All critical operations have MANDATORY VERIFICATION
- [ ] Path validation includes parent directory, absolute path, writability
- [ ] Fallback mechanisms exist for all agent operations
- [ ] Placeholder artifacts created on failure
- [ ] Command continues with degraded functionality on non-critical failures
- [ ] Checkpoint code reduced through abstraction

**Standards Reference**:
- Standard 0: Execution Enforcement (verification)
- Standard 13: Absolute Path Requirements
- Error Enhancement Guide

---

### Phase 5: Documentation, Testing, and Production Readiness

**Objective**: Complete documentation updates, create tests, and achieve production readiness

**Duration**: 1-2 hours

**Tasks**:
- [ ] Add command to command-reference.md
- [ ] Create command guide following _template-command-guide.md
- [ ] Add YAML frontmatter with metadata
- [ ] Document behavioral injection pattern in guides
- [ ] Add operational guidelines section
- [ ] Create test suite for critical paths
- [ ] Test Phase 0 library loading and failure modes
- [ ] Test agent invocation and fallback mechanisms
- [ ] Test path validation edge cases
- [ ] Validate against execution enforcement guide checklist
- [ ] Run full workflow integration test
- [ ] Update CHANGELOG with improvements
- [ ] Add migration notes for users

**Dependencies**: Phase 4 (requires complete implementation)

**Verification**:
- [ ] Command listed in command-reference.md
- [ ] Command guide created with complete documentation
- [ ] YAML frontmatter present with all metadata
- [ ] Test suite created with ≥80% coverage
- [ ] All tests passing
- [ ] Execution enforcement guide validation passing
- [ ] Integration test successful
- [ ] Documentation complete and accurate

**Standards Reference**:
- Documentation Standards
- Testing Protocols
- Template Usage Guide

---

## Rollback Strategy

If issues occur during implementation:

1. **Git-based rollback**: All changes committed per phase with clear commit messages
   - `git revert <commit-hash>` to undo specific phase
   - `git reset --hard <commit-hash>` to restore to pre-implementation state

2. **Backup retention**: Create backup of original optimize-claude.md
   - Location: `.claude/specs/730_*/backups/optimize-claude.md.backup`
   - Restoration: `cp backup optimize-claude.md`

3. **Phased implementation**: Each phase is self-contained and independently testable
   - Partial completion acceptable (phases 1-3 provide core improvements)
   - Phase 4 and 5 are enhancements, not blockers

4. **Fallback to current version**: Current command remains functional
   - Keep as `optimize-claude.md.old` during transition
   - Can revert command registry to point to old version if needed

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking existing workflows | Low | High | Maintain backward compatibility; test with existing CLAUDE.md files |
| Agent behavioral changes | Medium | Medium | Reference external behavioral files; no inline changes |
| Task tool syntax issues | Medium | Low | Clarify syntax early; provide fallback error messages |
| Path validation too strict | Low | Medium | Test with various project structures; add diagnostic messages |
| Performance degradation | Low | Low | Verification adds <100ms overhead; negligible impact |
| Documentation drift | Medium | Medium | Update docs in same phase as code changes |
| Test coverage gaps | Medium | Medium | Focus on critical paths; phase-based testing |

## Dependencies and Prerequisites

**Required**:
- Access to .claude/commands/optimize-claude.md
- Write permissions to .claude/docs/
- Git repository for versioning
- Research reports (already completed)

**Optional but Recommended**:
- Test execution environment
- Integration test suite
- Command validation tools

## Testing Strategy

**Unit Tests** (per phase):
- Phase 1: Library loading, role declaration validation
- Phase 2: Imperative language pattern detection
- Phase 3: Agent invocation format validation
- Phase 4: Path validation, fallback mechanism triggers
- Phase 5: Full workflow integration

**Integration Tests**:
- Run optimize-claude against sample CLAUDE.md files
- Verify all agents invoked correctly
- Confirm artifact creation at expected paths
- Test fallback mechanisms with simulated failures

**Regression Tests**:
- Compare output quality before/after changes
- Ensure no breaking changes to artifact structure
- Verify backward compatibility with existing workflows

## Notes

### Context Budget Considerations

Total implementation affects ~250 of 325 lines (77% of file). Research reports provide comprehensive context:
- Report 001: 19KB (command analysis)
- Report 002: 27KB (standards comparison)
- Report 003: 38KB (discrepancies)
- Total research: 86KB

To manage context budget:
1. Reference research reports by path, not inline content
2. Use metadata extraction for key findings (250-token summaries)
3. Implement phases sequentially to minimize active context
4. Archive completed phase notes to separate files

### Standards Compliance Tracking

| Standard | Current | Target | Phase |
|----------|---------|--------|-------|
| Standard 0 (Execution Enforcement) | 45% | 95% | 1, 2, 4 |
| Standard 0.5 (Agent Enforcement) | 50% | 95% | 2, 3 |
| Standard 9 (Orchestration) | 70% | 95% | 1, 3 |
| Standard 12 (Behavioral Injection) | 30% | 90% | 3 |
| Standard 13 (Absolute Paths) | 90% | 100% | 4 |
| Documentation Standards | 40% | 90% | 5 |

### Performance Impact

Expected performance changes:
- Phase 0 library loading: +50-100ms (one-time startup cost)
- Path validation: +10-20ms per path check
- Verification checkpoints: +5-10ms per checkpoint
- Fallback mechanisms: +0ms (only on failure path)
- **Total overhead**: <200ms for typical workflow
- **Benefit**: 95%+ reliability vs 85-90% current

### Migration Path

For users of the current optimize-claude command:
1. No changes required to existing CLAUDE.md files
2. Artifact output structure remains identical
3. Agent behavioral changes isolated to referenced files
4. Command invocation syntax unchanged: `/optimize-claude`
5. New features (fallback, resume) automatically available

### Future Enhancements (Out of Scope)

Potential future improvements not included in this plan:
- Parallel phase execution (currently sequential)
- Agent result caching for repeated runs
- Interactive mode for user input during workflow
- Dry-run mode to preview changes
- Custom agent selection via parameters
- Template customization for different project types

---

**Plan created using /plan command following Directory Protocols and Adaptive Planning standards**

# .claude/docs/ Refactor for State-Based Architecture

## Metadata
- **Date**: 2025-11-09
- **Feature**: Documentation Refactor - Align with State-Based Architecture
- **Scope**: Reorganize and enhance .claude/docs/ to reflect current state-based orchestration implementation
- **Estimated Phases**: 6 phases
- **Estimated Hours**: 20-30 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - 602 (State-Based Orchestrator Refactor - COMPLETED)
  - 613 (Fix coordinate state machine initialization - COMPLETED)
  - 617 (Fix indirect expansion errors - COMPLETED)
  - 620 (Fix coordinate bash history expansion - COMPLETED)
- **Research Context**: Based on analysis of recently implemented state-based architecture refactor

## Problem Statement

The .claude/docs/ directory structure was created before the major state-based orchestration refactor (Spec 602) and several critical bug fixes (Specs 613, 617, 620). While the documentation is comprehensive (122 markdown files across 13 directories), it needs reorganization and updates to:

1. **Reflect Current State-Based Architecture**: Documentation predates the state machine architecture, selective state persistence, and hierarchical supervisor coordination patterns
2. **Address Missing State Machine Documentation**: Limited documentation of workflow-state-machine.sh, state-persistence.sh, and checkpoint schema V2.0
3. **Consolidate Scattered State Management Content**: State management concepts spread across guides/, architecture/, and concepts/ without clear ownership
4. **Update Orchestration Command Guides**: /coordinate, /orchestrate guides need updates for bash block execution patterns and library re-sourcing
5. **Improve Discoverability**: 122 files can overwhelm users; need better navigation and cross-references
6. **Eliminate Duplication**: Some content duplicated between guides and architecture docs

### Current Structure Analysis

**Total Documentation**: 122 markdown files
- architecture/ - 4 files (NEW - created for state-based refactor)
- concepts/ - 16 files (including 10 patterns)
- guides/ - 42 files (largest section, some overlap)
- reference/ - 15 files
- workflows/ - 10 files
- troubleshooting/ - 4 files
- quick-reference/ - 6 files
- archive/ - 31 files (old content)

**Key Gaps Identified**:
1. No comprehensive state machine architecture guide in concepts/
2. Bash execution model and library re-sourcing not documented in troubleshooting/
3. Checkpoint schema V2.0 not documented in reference/
4. State persistence patterns not consolidated
5. No migration guide for phase-based → state-based orchestration
6. Verification pattern (verification-helpers.sh) usage not fully documented

## Success Criteria

- [ ] State-based architecture comprehensively documented in concepts/
- [ ] All recent implementations (specs 602, 613, 617, 620) reflected in documentation
- [ ] Bash execution model and library re-sourcing patterns documented
- [ ] Checkpoint schema V2.0 fully specified in reference/
- [ ] Clear navigation paths for state machine, state persistence, and orchestration
- [ ] Reduced duplication between architecture/, concepts/, and guides/
- [ ] Updated command guides (/coordinate, /orchestrate, /supervise) with current patterns
- [ ] Troubleshooting guide includes bash execution context issues (Spec 620)
- [ ] Migration guide for developers moving from phase-based to state-based patterns
- [ ] All cross-references updated to point to correct, current documentation

## Recommendations from Research

### Recent Implementation Analysis

**Spec 602 (State-Based Orchestrator Refactor)**:
- Introduced workflow-state-machine.sh (8 states, transition validation)
- Created state-persistence.sh (GitHub Actions pattern)
- Defined checkpoint schema V2.0
- Implemented hierarchical supervisors with state awareness
- Achieved 48.9% code reduction (3,420 → 1,748 lines)
- Performance: 67% faster state operations, 95.6% context reduction

**Spec 613 (Coordinate Initialization Fixes)**:
- Fixed indirect variable expansion in error handling
- Added TOPIC_PATH validation patterns
- Introduced defensive initialization checks

**Spec 617 (Fix Indirect Expansion Errors)**:
- Replaced ${!array[@]} with C-style loops and eval patterns
- Fixed 7 instances across workflow-initialization.sh and context-pruning.sh
- Documented safe alternatives to indirect expansion

**Spec 620 (Fix Coordinate Bash History Expansion)**:
- Discovered bash block subprocess isolation as root cause
- Implemented library re-sourcing pattern (source guards + re-sourcing in each block)
- Added verification-helpers.sh integration for fail-fast diagnostics
- Enhanced error handling with five-component error messages

### Documentation Gaps Analysis

**Gap 1: State Machine Architecture Missing from concepts/**
- Current: state-based-orchestration-overview.md in architecture/
- Problem: architecture/ is new, not well-integrated with concepts/
- Solution: Create concepts/state-machine-architecture.md as canonical reference
- Link from: guides/coordinate-command-guide.md, guides/state-machine-orchestrator-development.md

**Gap 2: Bash Execution Model Not in Troubleshooting**
- Current: Spec 620 documented bash block subprocess isolation
- Problem: Not documented in troubleshooting/ or guides/
- Solution: Add troubleshooting/bash-execution-context.md
- Update: guides/command-development-guide.md with bash block best practices

**Gap 3: Checkpoint Schema V2.0 Not Specified**
- Current: Mentioned in state-based-orchestration-overview.md
- Problem: No formal schema specification in reference/
- Solution: Create reference/checkpoint-schema-v2.md
- Link from: guides/implement-command-guide.md, concepts/patterns/checkpoint-recovery.md

**Gap 4: State Persistence Patterns Not Consolidated**
- Current: Scattered across multiple guides and architecture docs
- Problem: No single source of truth for when to use file-based vs stateless
- Solution: Create concepts/state-persistence-patterns.md
- Consolidate from: architecture/state-based-orchestration-overview.md, guides/

**Gap 5: Library Re-Sourcing Pattern Not Documented**
- Current: Implemented in Spec 620 but not documented
- Problem: Critical pattern for all orchestration commands
- Solution: Add to guides/command-development-guide.md Section 4
- Cross-reference from: troubleshooting/bash-execution-context.md

**Gap 6: Verification Pattern Usage Not Complete**
- Current: concepts/patterns/verification-fallback.md exists
- Problem: Doesn't cover verification-helpers.sh fail-fast pattern from Spec 620
- Solution: Update to verification-and-fail-fast.md with comprehensive coverage
- Add examples from coordinate.md implementation

## Implementation Phases

### Phase 1: Create Missing Core Concept Documentation
**Objective**: Fill critical gaps in conceptual documentation for state-based architecture
**Complexity**: Medium
**Priority**: HIGH

**Tasks:**

- [ ] **Task 1.1: Create concepts/state-machine-architecture.md**

  Comprehensive state machine architecture guide consolidating:
  - 8 explicit states (initialize, research, plan, implement, test, debug, document, complete)
  - State transition table and validation rules
  - Atomic transition pattern (validate → update → checkpoint)
  - Integration with checkpoint schema V2.0
  - When to use state-based vs simpler approaches

  Source content from:
  - architecture/state-based-orchestration-overview.md (sections 1-4)
  - .claude/lib/workflow-state-machine.sh (implementation reference)
  - specs/602.../plans/001_state_based_orchestrator_refactor.md

  Cross-references:
  - Link to: reference/checkpoint-schema-v2.md, concepts/state-persistence-patterns.md
  - Link from: guides/coordinate-command-guide.md, guides/state-machine-orchestrator-development.md

- [ ] **Task 1.2: Create concepts/state-persistence-patterns.md**

  Consolidate state persistence decision framework:
  - When to use file-based state (7 criteria from Spec 602)
  - When to use stateless recalculation (5 criteria)
  - GitHub Actions pattern implementation
  - Decision matrix with examples
  - Performance characteristics (67% improvement measured)

  Source content from:
  - architecture/state-based-orchestration-overview.md (section 4)
  - specs/602.../reports/002_state_management_synthesis.md
  - .claude/lib/state-persistence.sh

  Cross-references:
  - Link to: reference/checkpoint-schema-v2.md, concepts/state-machine-architecture.md
  - Link from: guides/command-development-guide.md, guides/orchestration-best-practices.md

- [ ] **Task 1.3: Create concepts/bash-execution-model.md**

  Document bash block execution patterns:
  - Subprocess isolation constraint (each block = separate process)
  - Why functions aren't available across blocks
  - Library re-sourcing pattern (source guards + re-sourcing)
  - When to split large bash blocks (<200 lines)
  - Safe alternatives to ${!VAR} and ${!array[@]}

  Source content from:
  - specs/620.../plans/001_coordinate_history_expansion_fix.md
  - specs/623.../reports/001_coordinate_orchestration_best_practices/
  - specs/617.../plans/001_fix_remaining_indirect_expansions.md

  Cross-references:
  - Link to: troubleshooting/bash-execution-context.md
  - Link from: guides/command-development-guide.md

**Files Created:**
- concepts/state-machine-architecture.md (~1,500 lines)
- concepts/state-persistence-patterns.md (~1,000 lines)
- concepts/bash-execution-model.md (~800 lines)

**Expected Duration**: 8-10 hours

---

### Phase 2: Create Missing Reference Documentation
**Objective**: Provide authoritative reference specs for schemas and APIs
**Complexity**: Medium
**Priority**: HIGH

**Tasks:**

- [ ] **Task 2.1: Create reference/checkpoint-schema-v2.md**

  Formal specification of checkpoint schema V2.0:
  - Complete JSON schema with field descriptions
  - State machine section structure
  - Supervisor coordination fields
  - Error state tracking (retry counters, failed states)
  - Migration from V1.3 schema
  - Backward compatibility guarantees

  Source content from:
  - .claude/lib/workflow-state-machine.sh (sm_save/sm_load functions)
  - architecture/state-based-orchestration-overview.md (section 6)
  - specs/602.../plans/001_state_based_orchestrator_refactor.md

  Cross-references:
  - Link to: concepts/state-machine-architecture.md, concepts/patterns/checkpoint-recovery.md
  - Link from: guides/implement-command-guide.md, guides/orchestration-best-practices.md

- [ ] **Task 2.2: Create reference/state-machine-api.md**

  API reference for workflow-state-machine.sh functions:
  - sm_init() - Initialize state machine
  - sm_transition() - Validate and execute state transition
  - sm_save() / sm_load() - Checkpoint persistence
  - sm_current_state(), sm_is_terminal() - State queries
  - map_phase_to_state() / map_state_to_phase() - Migration helpers

  Source content from:
  - .claude/lib/workflow-state-machine.sh (function signatures and docs)
  - architecture/workflow-state-machine.md

  Cross-references:
  - Link to: reference/library-api.md (add state machine section)
  - Link from: guides/state-machine-orchestrator-development.md

- [ ] **Task 2.3: Update reference/library-api.md**

  Add state management libraries:
  - workflow-state-machine.sh functions
  - state-persistence.sh functions (init_workflow_state, load_workflow_state, append_workflow_state)
  - verification-helpers.sh functions (verify_file_created)

  Cross-references:
  - Link to: reference/checkpoint-schema-v2.md, reference/state-machine-api.md

**Files Modified/Created:**
- reference/checkpoint-schema-v2.md (~1,000 lines)
- reference/state-machine-api.md (~800 lines)
- reference/library-api.md (add ~300 lines)

**Expected Duration**: 6-8 hours

---

### Phase 3: Update Command Guides for State-Based Patterns
**Objective**: Update all orchestration command guides with current implementation
**Complexity**: Medium
**Priority**: HIGH

**Tasks:**

- [ ] **Task 3.1: Update guides/coordinate-command-guide.md**

  Add sections:
  - State machine integration (how /coordinate uses 8 states)
  - Library re-sourcing pattern (implemented in Spec 620)
  - Verification checkpoints (fail-fast pattern from Spec 620)
  - Five-component error message format
  - Wave-based parallel execution

  Update existing sections:
  - Architecture section → reference state machine library
  - Troubleshooting → link to troubleshooting/bash-execution-context.md

  Cross-references:
  - Link to: concepts/state-machine-architecture.md, concepts/bash-execution-model.md
  - Link to: troubleshooting/bash-execution-context.md

- [ ] **Task 3.2: Update guides/orchestrate-command-guide.md**

  Add sections:
  - State machine integration notes
  - Library re-sourcing requirements
  - Differences from /coordinate (if any)

  Cross-references:
  - Link to: guides/coordinate-command-guide.md (canonical state machine reference)

- [ ] **Task 3.3: Update guides/supervise-guide.md**

  Add sections:
  - State machine integration (sequential vs parallel differences)
  - Supervisor checkpoint coordination
  - State-aware supervisor patterns

  Cross-references:
  - Link to: architecture/hierarchical-supervisor-coordination.md

- [ ] **Task 3.4: Update guides/command-development-guide.md**

  Add Section 4: Bash Block Execution Patterns
  - Library re-sourcing in every bash block
  - Source guards for idempotent re-sourcing
  - Bash block size limits (<200 lines recommended)
  - Safe alternatives to indirect expansion (${!VAR})
  - Export patterns between blocks

  Add Section 5: State Management Integration
  - When to use state machine (vs simple phase tracking)
  - How to integrate workflow-state-machine.sh
  - Checkpoint coordination patterns

  Cross-references:
  - Link to: concepts/bash-execution-model.md, concepts/state-machine-architecture.md
  - Link to: reference/state-machine-api.md

**Files Modified:**
- guides/coordinate-command-guide.md (add ~500 lines)
- guides/orchestrate-command-guide.md (add ~300 lines)
- guides/supervise-guide.md (add ~200 lines)
- guides/command-development-guide.md (add ~800 lines)

**Expected Duration**: 8-10 hours

---

### Phase 4: Create Troubleshooting Documentation
**Objective**: Document common issues and solutions from recent bug fixes
**Complexity**: Low-Medium
**Priority**: MEDIUM

**Tasks:**

- [ ] **Task 4.1: Create troubleshooting/bash-execution-context.md**

  Document bash block execution issues:
  - Symptom: "!: command not found" errors
  - Root cause: Subprocess isolation, not history expansion
  - Solution: Library re-sourcing pattern with source guards
  - Symptom: "TOPIC_PATH: unbound variable" errors
  - Root cause: Initialization failure without defensive checks
  - Solution: Defensive initialization and validation patterns
  - Prevention: Bash block best practices checklist

  Source content from:
  - specs/620.../plans/001_coordinate_history_expansion_fix.md
  - specs/617.../plans/001_fix_remaining_indirect_expansions.md
  - specs/613.../plans/001_coordinate_initialization_fixes.md

  Cross-references:
  - Link to: concepts/bash-execution-model.md
  - Link from: guides/coordinate-command-guide.md, guides/command-development-guide.md

- [ ] **Task 4.2: Update troubleshooting/orchestration-troubleshooting.md** (if exists)

  Add sections:
  - Bash execution context issues (link to bash-execution-context.md)
  - State machine transition errors
  - Checkpoint corruption recovery

  Or create if doesn't exist.

**Files Created/Modified:**
- troubleshooting/bash-execution-context.md (~1,000 lines)
- troubleshooting/orchestration-troubleshooting.md (add ~300 lines or create)

**Expected Duration**: 4-5 hours

---

### Phase 5: Consolidate and Reorganize Architecture Documentation
**Objective**: Reduce duplication, integrate architecture/ with concepts/
**Complexity**: Medium
**Priority**: MEDIUM

**Tasks:**

- [ ] **Task 5.1: Integrate architecture/ into concepts/ or guides/**

  Decision: Should architecture/ remain separate or merge into concepts/?

  Option A: Merge into concepts/ (recommended)
  - Move state-based-orchestration-overview.md → concepts/state-based-orchestration.md
  - Content already covered in new concepts/state-machine-architecture.md and concepts/state-persistence-patterns.md
  - Reduce to overview linking to detailed concept docs

  Option B: Keep architecture/ as deep-dive section
  - Clarify distinction: architecture/ = comprehensive multi-page guides, concepts/ = single-topic explanations
  - Update README.md with clear guidance on when to use each

  Recommendation: Option A (consolidate) to reduce navigation complexity

- [ ] **Task 5.2: Update Cross-References**

  Global search and replace:
  - Update all links to architecture/state-based-orchestration-overview.md
  - Point to new concepts/state-machine-architecture.md and concepts/state-persistence-patterns.md
  - Update main docs/README.md navigation

- [ ] **Task 5.3: Archive or Delete Obsolete Documentation**

  Candidates for archival:
  - Any pre-state-machine orchestration patterns
  - Phase-based orchestration guides (if superseded)
  - Migration guides that are no longer relevant

  Process:
  - Review archive/ directory current contents
  - Move obsolete docs to archive/ with date marker
  - Update navigation to remove archived links

**Files Modified:**
- Potentially move 4 files from architecture/ → concepts/
- Update ~20-30 files with cross-reference corrections
- Archive 5-10 obsolete files

**Expected Duration**: 5-6 hours

---

### Phase 6: Update Navigation and Create Migration Guide
**Objective**: Improve discoverability and help developers transition to state-based patterns
**Complexity**: Medium
**Priority**: MEDIUM

**Tasks:**

- [ ] **Task 6.1: Update docs/README.md Navigation**

  Add state-based architecture quick paths:
  - "I want to understand state machine architecture" → concepts/state-machine-architecture.md
  - "I want to implement state-based orchestration" → guides/state-machine-orchestrator-development.md
  - "I'm getting bash execution errors" → troubleshooting/bash-execution-context.md
  - "I want to understand state persistence" → concepts/state-persistence-patterns.md

  Update existing quick paths:
  - "Orchestrate complete workflows" → emphasize /coordinate as recommended default
  - "Fix broken orchestration" → add bash-execution-context.md link

- [ ] **Task 6.2: Create guides/phase-to-state-migration.md**

  Guide for migrating phase-based commands to state-based:
  - Side-by-side comparison (phase numbers vs named states)
  - Migration checklist (10 steps)
  - Code examples (before/after)
  - Validation testing patterns
  - Backward compatibility considerations

  Source content from:
  - architecture/state-based-orchestration-overview.md (section 8)
  - specs/602.../plans/001_state_based_orchestrator_refactor.md

  Cross-references:
  - Link to: concepts/state-machine-architecture.md, reference/state-machine-api.md
  - Link from: guides/command-development-guide.md

- [ ] **Task 6.3: Update concepts/README.md and guides/README.md**

  Add new documents to section lists:
  - concepts/README.md: Add state-machine-architecture, state-persistence-patterns, bash-execution-model
  - guides/README.md: Add phase-to-state-migration, updated command guides

  Update navigation links.

- [ ] **Task 6.4: Create Quick Reference for State Machine**

  quick-reference/state-machine-cheatsheet.md:
  - 8 states with descriptions (one-line each)
  - Valid transitions diagram (ASCII art or mermaid)
  - Common API functions quick reference
  - State machine integration checklist (5 steps)

  Cross-references:
  - Link to: concepts/state-machine-architecture.md (comprehensive guide)

**Files Created/Modified:**
- docs/README.md (update navigation, add ~100 lines)
- guides/phase-to-state-migration.md (~1,200 lines)
- concepts/README.md (add ~150 lines)
- guides/README.md (add ~200 lines)
- quick-reference/state-machine-cheatsheet.md (~600 lines)

**Expected Duration**: 6-8 hours

---

## Testing Strategy

### Phase 1-2 Testing: Content Accuracy Validation
- Verify all code examples compile and execute correctly
- Cross-check API references against actual library implementations
- Validate checkpoint schema examples against V2.0 implementation

### Phase 3 Testing: Command Guide Accuracy
- Test /coordinate, /orchestrate, /supervise workflows
- Verify bash block patterns work as documented
- Validate library re-sourcing examples

### Phase 4 Testing: Troubleshooting Effectiveness
- Reproduce documented errors
- Verify solutions resolve issues
- Test bash execution context examples

### Phase 5-6 Testing: Navigation and Completeness
- Follow all cross-reference links (verify no broken links)
- Walk through "I want to..." paths from main README
- Verify migration guide accuracy with test migration

### Overall Testing
- Build documentation site (if using static site generator)
- Spell check and grammar review
- Technical review by another developer

## Risk Assessment

**Low Risk (Phases 1-3)**:
- Creating new documentation - no breaking changes
- Updating guides - existing guides remain available

**Medium Risk (Phase 5)**:
- Reorganizing architecture/ → concepts/ may break external links
- Archival decisions may remove useful content
- Mitigation: Careful review, redirects for moved files

**Low Risk (Phase 6)**:
- Navigation updates straightforward
- Migration guide is new content (no breaking changes)

## Dependencies

**Prerequisites:**
- Specs 602, 613, 617, 620 completed (DONE)
- Current .claude/docs/ structure (122 files)
- Access to implementation files (.claude/lib/, .claude/commands/)

**Integration:**
- Follows Diataxis framework (already established)
- Uses existing directory structure (concepts/, guides/, reference/, workflows/)
- Maintains cross-reference patterns

**No Breaking Changes:**
- New documentation added, old documentation archived (not deleted)
- Existing guides remain functional during updates
- Cross-references updated incrementally

## Expected Outcomes

### Phase 1 Outcomes
- 3 new comprehensive concept docs (3,300 lines total)
- State machine, state persistence, bash execution model fully documented
- Clear separation of concerns (concepts vs implementation)

### Phase 2 Outcomes
- Formal checkpoint schema V2.0 specification
- Complete state machine API reference
- Updated library API reference with state management functions

### Phase 3 Outcomes
- All orchestration command guides current with implementation
- Bash block execution patterns documented in command guide
- State machine integration examples for all 3 orchestrators

### Phase 4 Outcomes
- Bash execution context troubleshooting guide
- Common error patterns from Specs 613, 617, 620 documented
- Prevention checklists for command developers

### Phase 5 Outcomes
- Reduced duplication (architecture/ → concepts/)
- Clearer navigation (no competing authorities)
- Obsolete content properly archived

### Phase 6 Outcomes
- Improved discoverability (updated main README navigation)
- Migration guide for phase-based → state-based transition
- Quick reference for state machine API

### Overall Outcomes
- Comprehensive state-based architecture documentation
- Reduced documentation redundancy
- Improved developer onboarding experience
- All recent implementations (602, 613, 617, 620) fully reflected
- Clear, authoritative references for all major components

**Total New/Updated Content**: ~15,000-18,000 lines across 25-30 files

**Time Investment**: 37-47 hours across 6 phases

## Implementation Notes

### Content Sourcing Strategy

**Prioritize Existing Content**:
- Reuse from architecture/state-based-orchestration-overview.md (1,748 lines available)
- Extract from implementation plans (specs/602, 613, 617, 620)
- Reference actual code (.claude/lib/) for accuracy

**Avoid Duplication**:
- Create canonical references in concepts/
- Link from guides/ instead of duplicating
- Use cross-references extensively

**Follow Diataxis Framework**:
- concepts/ = understanding-oriented (why it works this way)
- guides/ = task-oriented (how to do X)
- reference/ = information-oriented (what does function Y do)
- workflows/ = learning-oriented (step-by-step tutorial)

### Writing Standards Compliance

**Clean-Break Approach**:
- Document current state, not history
- No "previously" or "new in version X" markers
- Focus on what it is, not what it was

**Timeless Writing**:
- Avoid temporal markers
- Present tense for current implementation
- Past tense only in explicit migration guides

**Single Source of Truth**:
- Identify authoritative location for each concept
- All other references link to authority
- Update authority, not copies

### Cross-Reference Strategy

**Bi-Directional Links**:
- "Link to" (this document references X for details)
- "Link from" (X references this document as authority)

**Navigation Paths**:
- Main README → section README → detailed guide
- Quick reference → comprehensive concept
- Troubleshooting → solution guide → concept explanation

## Success Metrics

### Quantitative Metrics
- [ ] 15-20 new documentation files created
- [ ] 10-15 existing files updated
- [ ] 5-10 files archived
- [ ] 0 broken links in final review
- [ ] 100% of recent specs (602, 613, 617, 620) reflected in docs

### Qualitative Metrics
- [ ] Clear navigation path from "I want to understand state machines" to comprehensive guide
- [ ] Developers can find bash execution troubleshooting in <2 clicks from main README
- [ ] State machine API reference complete and accurate
- [ ] Migration guide enables phase-based → state-based transition
- [ ] No conflicting authorities (single source of truth for each concept)

---

## Summary

This plan reorganizes .claude/docs/ to align with the recently implemented state-based orchestration architecture, addressing 6 critical gaps:

1. **Missing state machine conceptual documentation** → Create concepts/state-machine-architecture.md
2. **No bash execution model guide** → Create concepts/bash-execution-model.md and troubleshooting/bash-execution-context.md
3. **Checkpoint schema V2.0 not specified** → Create reference/checkpoint-schema-v2.md
4. **State persistence patterns scattered** → Create concepts/state-persistence-patterns.md
5. **Command guides outdated** → Update guides/coordinate-command-guide.md and others
6. **Navigation complexity** → Consolidate architecture/ into concepts/, update README navigation

**Approach**: 6 phases over 20-30 hours, creating ~15-20 new files and updating ~10-15 existing files. Follows Diataxis framework, writing standards (clean-break, timeless, single source of truth), and existing documentation patterns.

**Priority Path**: Phases 1-3 (core concepts, references, command guides) provide immediate value and can be implemented first.

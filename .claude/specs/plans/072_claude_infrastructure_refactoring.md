# .claude/ Infrastructure Systematic Refactoring

## Metadata
- **Date**: 2025-10-18
- **Feature**: Systematic refactoring of .claude/ commands and agents infrastructure
- **Scope**: Agent registry completion, utility modularization, documentation integration, discovery/validation systems
- **Estimated Phases**: 6 high-level phases (designed for successive /expand expansion)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - Internal research: Documentation structure analysis (41 files, Diataxis framework)
  - Internal research: Command architecture analysis (21 commands, 13,193 lines)
  - Internal research: Agent architecture analysis (19 agents + registry)
  - Internal research: Shared utilities analysis (44 libraries, 17,037 lines)

## Overview

This plan addresses systematic refactoring of the entire `.claude/` infrastructure based on comprehensive research findings across four domains: documentation, commands, agents, and shared utilities. The refactoring prioritizes completion of incomplete systems (agent registry at 2/19 agents), modularization of large consolidated utilities (artifact-operations.sh at 2,713 lines), integration of recent documentation changes, and creation of discovery/validation infrastructure.

### Current State Summary

**Documentation (41 markdown files)**
- Well-organized Diataxis structure: Reference (5), Guides (11), Concepts (4), Workflows (6), Archive (8)
- Recent consolidation completed (2025-10-17)
- Main README comprehensive (619 lines)
- New hierarchical-agent-workflow.md requires integration

**Commands (21 active commands, 13,193 lines)**
- Reference-based composition: 61.3% reduction via 10 shared documentation files
- Heavy utility integration: 30 modular libraries
- Recent Stage 3 consolidation: 3 bundles (plan-core, unified-logger, base-utils)
- Incomplete extraction: references to non-existent shared files

**Agents (19 definitions + performance registry)**
- 11 specialized agents + 6 hierarchical coordination agents
- Strong infrastructure: metadata extraction, context pruning (99% reduction)
- **Critical gap**: Registry only tracks 2/19 agents
- Large consolidated utility: artifact-operations.sh (2,713 lines, multiple concerns)

**Shared Utilities (44 libraries, 17,037 lines)**
- Well-organized into 9 functional domains
- Comprehensive test coverage: 54 test files
- 6 deprecated wrappers for backward compatibility
- Some utilities very large, could benefit from further splitting

### Key Refactoring Objectives

1. **Complete Agent Registry**: Register all 19 agents with proper metadata and performance tracking
2. **Modularize Large Utilities**: Split artifact-operations.sh into focused modules (hierarchical-agent-utils.sh, metadata-extraction.sh, context-pruning.sh)
3. **Finish Command Documentation Extraction**: Remove dead references, complete shared documentation
4. **Integrate Documentation Updates**: Merge hierarchical-agent-workflow.md, clean up archive references
5. **Create Discovery Systems**: Auto-registration, validation utilities, structure analysis tools

## Success Criteria

- [ ] All 19 agents registered in agent-registry.json with accurate metadata
- [ ] artifact-operations.sh split into 3-4 focused modules (<1000 lines each)
- [ ] All command shared documentation references valid and complete
- [ ] hierarchical-agent-workflow.md integrated into documentation structure
- [ ] Agent discovery and validation utilities operational
- [ ] All tests passing (54 test files + new validation tests)
- [ ] Zero dead references in commands/shared/ or documentation
- [ ] Backward compatibility maintained for all existing commands/agents
- [ ] Documentation updated to reflect new modular structure

## Technical Design

### Architecture Decisions

**1. Agent Registry Enhancement**

Current state: `agent-registry.json` tracks 2/19 agents with basic metrics (invocations, success rate, duration).

**Decision**: Expand registry schema to include:
```json
{
  "agents": {
    "agent-name": {
      "type": "specialized|hierarchical",
      "category": "research|planning|implementation|debugging|documentation",
      "description": "Brief purpose statement",
      "tools": ["Read", "Write", "Grep", "Glob"],
      "metrics": {
        "total_invocations": 0,
        "successful_invocations": 0,
        "failed_invocations": 0,
        "average_duration_seconds": 0,
        "last_invocation": "ISO-8601 timestamp"
      },
      "dependencies": ["utility-name", "another-utility"],
      "behavioral_file": ".claude/agents/agent-name.md"
    }
  }
}
```

**Rationale**: Enhanced metadata enables dependency tracking, categorization for discovery, and comprehensive performance analysis.

**2. Utility Modularization Strategy**

Current state: `artifact-operations.sh` (2,713 lines) handles 6 distinct concerns:
- Metadata extraction (extract_report_metadata, extract_plan_metadata)
- Forward message patterns (forward_message, parse_subagent_response)
- Recursive supervision (invoke_sub_supervisor, track_supervision_depth)
- Context pruning (prune_subagent_output, prune_phase_metadata)
- Supervision tracking (generate_supervision_tree)
- General artifact operations

**Decision**: Split into focused modules:
```
.claude/lib/
├── metadata-extraction.sh (~600 lines)
│   └── extract_report_metadata, extract_plan_metadata, load_metadata_on_demand
├── hierarchical-agent-coordination.sh (~800 lines)
│   └── invoke_sub_supervisor, track_supervision_depth, generate_supervision_tree
├── context-pruning.sh (~500 lines)
│   └── prune_subagent_output, prune_phase_metadata, apply_pruning_policy
├── forward-message-patterns.sh (~400 lines)
│   └── forward_message, parse_subagent_response, create_minimal_handoff
└── artifact-registry.sh (~400 lines)
    └── General artifact registration and tracking
```

**Backward Compatibility**: Maintain `artifact-operations.sh` as a wrapper that sources all split modules:
```bash
# artifact-operations.sh (deprecated wrapper for v2.0 compatibility)
source "$(dirname "${BASH_SOURCE[0]}")/metadata-extraction.sh"
source "$(dirname "${BASH_SOURCE[0]}")/hierarchical-agent-coordination.sh"
source "$(dirname "${BASH_SOURCE[0]}")/context-pruning.sh"
source "$(dirname "${BASH_SOURCE[0]}")/forward-message-patterns.sh"
source "$(dirname "${BASH_SOURCE[0]}")/artifact-registry.sh"
```

**Rationale**: Focused modules improve maintainability, testing, and discoverability. Wrapper ensures zero breaking changes for existing commands.

**3. Command Shared Documentation Completion**

Current state: `commands/shared/` has 10 documented patterns, but commands reference non-existent files (error-recovery.md, context-management.md in orchestrate.md).

**Decision**:
- Audit all command references to `shared/` files
- Create missing documentation or remove dead references
- Standardize shared documentation index in `commands/shared/README.md`
- Extract additional common patterns from commands (identified 3-5 more candidates)

**Rationale**: Clean references improve command maintainability and reduce confusion.

**4. Documentation Integration Strategy**

Current state:
- `hierarchical-agent-workflow.md` exists but not in main README navigation
- Archive has 8 files still referenced in some navigation links
- Main README very comprehensive (619 lines) but manageable

**Decision**:
- Add hierarchical-agent-workflow.md to Workflows section of main README
- Update navigation links to remove archive references
- Create archive/README.md explaining historical context
- Maintain current Diataxis structure (working well)

**Rationale**: Preserve strong documentation organization while integrating recent additions cleanly.

**5. Discovery and Validation Utilities**

**New utilities to create**:

```bash
.claude/lib/agent-discovery.sh
# Auto-scan .claude/agents/ and register untracked agents
# Validate agent frontmatter and behavioral guidelines structure
# Generate agent schema compliance reports

.claude/lib/command-discovery.sh
# Scan .claude/commands/ for metadata extraction
# Validate command structure and dependencies
# Generate command inventory reports

.claude/lib/structure-validator.sh
# Validate .claude/ directory structure compliance
# Check for dead references across all files
# Verify cross-references between docs/commands/agents/utilities

.claude/lib/dependency-mapper.sh
# Map which commands use which utilities
# Map which agents depend on which utilities
# Generate dependency graphs and circular dependency warnings
```

**Rationale**: Automated discovery and validation prevent drift between actual and documented state. Enable proactive maintenance.

### Component Interactions

```
┌─────────────────────────────────────────────────────────────────┐
│                  .claude/ Infrastructure                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────┐      ┌──────────────┐     ┌──────────────┐ │
│  │  Commands     │─────>│  Utilities   │<────│   Agents     │ │
│  │  (21 files)   │      │ (44 modules) │     │ (19 agents)  │ │
│  └───────────────┘      └──────────────┘     └──────────────┘ │
│         │                      │                     │         │
│         │                      │                     │         │
│         v                      v                     v         │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │            Discovery & Validation Layer (NEW)             │ │
│  │  - agent-discovery.sh     - command-discovery.sh         │ │
│  │  - structure-validator.sh - dependency-mapper.sh         │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              v                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                  Registry Systems                          │ │
│  │  - agent-registry.json (enhanced)                         │ │
│  │  - command-metadata.json (NEW)                            │ │
│  │  - utility-dependency-map.json (NEW)                      │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                 │
│                              v                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              Documentation (41 files)                      │ │
│  │  Reference → Guides → Concepts → Workflows                │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Discovery Phase**: Utilities scan `.claude/` structure, extract metadata
2. **Registration Phase**: Auto-populate registries with discovered components
3. **Validation Phase**: Check cross-references, dependencies, structure compliance
4. **Reporting Phase**: Generate inventory, dependency graphs, compliance reports
5. **Maintenance Phase**: Continuous validation via pre-commit hooks (future)

## Implementation Phases

**Note**: Each phase below is designed as a high-level overview suitable for expansion via `/expand` command. Phases are ordered by dependency and priority.

### Phase 1: Agent Registry Foundation and Discovery
**Objective**: Complete agent registry infrastructure and auto-discovery system
**Complexity**: Medium
**Dependencies**: None
**Estimated Expansion**: 8-12 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Enhance agent-registry.json schema with new metadata fields (type, category, tools, dependencies)
- [ ] Create agent-discovery.sh utility for auto-scanning .claude/agents/
- [ ] Implement agent frontmatter validation (schema compliance checking)
- [ ] Register all 19 agents with complete metadata
- [ ] Create agent-registry-utils.sh enhancements for new schema
- [ ] Add tests for agent discovery and validation

**Testing**:
- Verify all 19 agents registered with accurate metadata
- Test auto-discovery on new agent additions
- Validate schema compliance checking
- Run agent-registry-utils.sh tests

**Success Criteria**:
- agent-registry.json contains all 19 agents
- agent-discovery.sh operational and tested
- All agents pass frontmatter validation

**Expansion Notes**: When expanded, this phase should break down into:
1. Schema design stage (JSON structure, validation rules)
2. Discovery utility implementation stage
3. Registry population stage
4. Testing and validation stage

---

### Phase 2: Utility Modularization - Split artifact-operations.sh
**Objective**: Split 2,713-line artifact-operations.sh into focused modules with backward compatibility
**Complexity**: High
**Dependencies**: None (independent refactoring)
**Estimated Expansion**: 15-20 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Analyze artifact-operations.sh function dependencies and groupings
- [ ] Create metadata-extraction.sh module (~600 lines)
- [ ] Create hierarchical-agent-coordination.sh module (~800 lines)
- [ ] Create context-pruning.sh module (~500 lines)
- [ ] Create forward-message-patterns.sh module (~400 lines)
- [ ] Create artifact-registry.sh module (~400 lines)
- [ ] Update artifact-operations.sh as compatibility wrapper
- [ ] Update all sourcing references in commands and agents
- [ ] Create comprehensive tests for each new module
- [ ] Validate backward compatibility

**Testing**:
- Each module: unit tests for all exported functions
- Integration tests: verify wrapper sources all modules correctly
- Regression tests: all existing commands/agents work unchanged
- Performance tests: ensure no significant overhead from splitting

**Success Criteria**:
- All 5 new modules created and tested
- artifact-operations.sh wrapper maintains 100% compatibility
- Zero breaking changes for existing commands
- All 54 existing tests still pass

**Expansion Notes**: When expanded, this phase should break down into:
1. Dependency analysis and module boundary definition
2. Module extraction stages (one per module)
3. Wrapper creation and testing stage
4. Reference update stage
5. Comprehensive testing and validation stage

---

### Phase 3: Command Shared Documentation Completion
**Objective**: Audit and complete command shared documentation, remove dead references
**Complexity**: Low-Medium
**Dependencies**: None
**Estimated Expansion**: 6-10 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Audit all command references to commands/shared/ files
- [ ] Identify missing shared documentation (error-recovery.md, context-management.md, etc.)
- [ ] Create missing documentation or remove dead references
- [ ] Extract additional common patterns from commands (3-5 candidates)
- [ ] Standardize commands/shared/README.md as index
- [ ] Update command files to reference correct shared docs
- [ ] Add validation to structure-validator.sh for shared doc references

**Testing**:
- Verify all shared doc references resolve correctly
- Test shared documentation examples are current
- Validate no dead references in any command file
- Check commands/shared/README.md completeness

**Success Criteria**:
- Zero dead references in commands
- All referenced shared docs exist and are current
- commands/shared/README.md provides complete index
- New validation prevents future dead references

**Expansion Notes**: When expanded, this phase should break down into:
1. Audit and inventory stage
2. Missing documentation creation stage
3. Reference cleanup stage
4. Validation integration stage

---

### Phase 4: Documentation Integration and Navigation Updates
**Objective**: Integrate hierarchical-agent-workflow.md and clean up archive references
**Complexity**: Low
**Dependencies**: None
**Estimated Expansion**: 5-8 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Add hierarchical-agent-workflow.md to Workflows section in main README
- [ ] Update all navigation links to remove archive references
- [ ] Create .claude/docs/archive/README.md explaining historical context
- [ ] Review main README for potential section extractions (optional optimization)
- [ ] Update cross-references in related documentation
- [ ] Validate all internal links resolve correctly

**Testing**:
- Check all internal links in main README
- Verify hierarchical-agent-workflow.md accessible from navigation
- Validate archive references don't appear in active docs
- Test documentation structure with structure-validator.sh

**Success Criteria**:
- hierarchical-agent-workflow.md integrated into main navigation
- Zero archive references in active documentation
- All internal links validated and working
- Documentation structure maintains Diataxis integrity

**Expansion Notes**: When expanded, this phase should break down into:
1. Navigation update stage
2. Archive cleanup stage
3. Cross-reference validation stage
4. Optional optimization stage (if main README needs extraction)

---

### Phase 5: Discovery and Validation Infrastructure
**Objective**: Create comprehensive discovery and validation utilities for ongoing maintenance
**Complexity**: Medium-High
**Dependencies**: Phase 1 (agent-discovery.sh pattern), Phase 2 (modular utilities)
**Estimated Expansion**: 12-18 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Create command-discovery.sh for command metadata extraction
- [ ] Create structure-validator.sh for cross-reference checking
- [ ] Create dependency-mapper.sh for dependency graph generation
- [ ] Implement command-metadata.json registry
- [ ] Implement utility-dependency-map.json tracking
- [ ] Add validation for command dependencies (dependent-commands metadata)
- [ ] Create comprehensive test suite for discovery utilities
- [ ] Generate initial dependency graphs and compliance reports

**Testing**:
- Test command-discovery.sh scans all 21 commands
- Test structure-validator.sh finds dead references
- Test dependency-mapper.sh generates accurate graphs
- Validate registries auto-update on structure changes
- Test all discovery utilities with edge cases

**Success Criteria**:
- All 4 discovery utilities operational and tested
- command-metadata.json and utility-dependency-map.json populated
- Dependency graphs generated successfully
- Structure validation catches all known issues

**Expansion Notes**: When expanded, this phase should break down into:
1. command-discovery.sh implementation stage
2. structure-validator.sh implementation stage
3. dependency-mapper.sh implementation stage
4. Registry population stage
5. Testing and reporting stage

---

### Phase 6: Integration Testing and Documentation Updates
**Objective**: Comprehensive testing of all refactored components and documentation updates
**Complexity**: Medium
**Dependencies**: Phases 1-5 (all previous phases)
**Estimated Expansion**: 8-12 detailed tasks when expanded

**High-Level Tasks**:
- [ ] Run full test suite (54 existing + new discovery tests)
- [ ] Perform integration testing across commands, agents, utilities
- [ ] Validate backward compatibility for all existing workflows
- [ ] Update all affected documentation (guides, reference, concepts)
- [ ] Generate refactoring summary report
- [ ] Update CLAUDE.md with new utilities and registries
- [ ] Create migration guide for users (if needed)
- [ ] Performance benchmarking (ensure no regressions)

**Testing**:
- Full .claude/tests/run_all_tests.sh execution
- Test all 21 commands with refactored infrastructure
- Test all hierarchical agent workflows
- Validate discovery utilities in real scenarios
- Performance comparison before/after refactoring

**Success Criteria**:
- 100% test pass rate (existing + new tests)
- Zero breaking changes for existing users
- All documentation updated and accurate
- Performance metrics show no significant regression
- Refactoring summary report complete

**Expansion Notes**: When expanded, this phase should break down into:
1. Testing orchestration stage (existing + new tests)
2. Integration validation stage
3. Documentation update stage (per category: reference, guides, concepts)
4. Performance benchmarking stage
5. Summary and migration guide stage

---

## Phase Dependencies

```
Phase 1: Agent Registry Foundation
   │
   ├─> Phase 5: Discovery Infrastructure (uses agent-discovery.sh pattern)
   │
Phase 2: Utility Modularization
   │
   ├─> Phase 5: Discovery Infrastructure (validates modular utilities)
   │
Phase 3: Command Documentation Completion
   │
Phase 4: Documentation Integration
   │
   └─> All phases converge into:

       Phase 6: Integration Testing and Documentation Updates
```

**Parallel Execution Opportunities**:
- Phases 1, 2, 3, 4 are independent and can be executed in parallel or any order
- Phase 5 depends on Phases 1 and 2 (for patterns and validation targets)
- Phase 6 must be last (validates all previous work)

**Wave-Based Execution Recommendation**:
- **Wave 1** (Parallel): Phases 1, 2, 3, 4
- **Wave 2** (Sequential): Phase 5 (depends on Wave 1)
- **Wave 3** (Sequential): Phase 6 (final validation)

## Testing Strategy

### Test Organization

**Existing Test Coverage** (54 test files in .claude/tests/):
- Parsing utilities: test_parsing_utilities.sh
- Command integration: test_command_integration.sh
- Progressive operations: test_progressive_*.sh
- State management: test_state_management.sh
- Shared utilities: test_shared_utilities.sh
- Adaptive planning: test_adaptive_planning.sh (16 tests)
- Revise automation: test_revise_automode.sh (18 tests)

**New Tests to Create**:
- test_agent_discovery.sh (agent scanning, validation, registration)
- test_metadata_extraction.sh (split module from artifact-operations.sh)
- test_hierarchical_coordination.sh (split module)
- test_context_pruning.sh (split module)
- test_forward_message.sh (split module)
- test_artifact_registry.sh (split module)
- test_command_discovery.sh (command metadata extraction)
- test_structure_validator.sh (cross-reference validation)
- test_dependency_mapper.sh (dependency graph generation)
- test_backward_compatibility.sh (ensure no breaking changes)

### Testing Approach

**Unit Testing**:
- Each new module: test all exported functions independently
- Each discovery utility: test scanning, validation, reporting functions
- Registry operations: test read, write, update, query functions

**Integration Testing**:
- artifact-operations.sh wrapper: verify sources all modules correctly
- Commands: test with new modular utilities
- Agents: test with enhanced registry and discovery
- Discovery utilities: test on complete .claude/ structure

**Regression Testing**:
- All existing commands must work unchanged
- All existing agent workflows must work unchanged
- All 54 existing tests must pass
- No performance degradation

**Validation Testing**:
- structure-validator.sh: catches known issues (dead references, missing files)
- agent-discovery.sh: finds all 19 agents accurately
- command-discovery.sh: extracts correct metadata from all 21 commands
- dependency-mapper.sh: generates accurate dependency graphs

### Test Execution

**Continuous Testing**:
```bash
# Run full test suite
.claude/tests/run_all_tests.sh

# Run category-specific tests
.claude/tests/run_all_tests.sh --category agent
.claude/tests/run_all_tests.sh --category discovery
.claude/tests/run_all_tests.sh --category integration

# Run backward compatibility tests
.claude/tests/test_backward_compatibility.sh
```

**Coverage Target**: ≥80% for new code, maintain ≥60% baseline

## Documentation Requirements

### Documentation Updates Needed

**Reference Documentation**:
- [ ] Update agent-reference.md with enhanced registry schema
- [ ] Update command-reference.md with shared documentation index
- [ ] Create discovery-utilities-reference.md for new utilities

**Guides**:
- [ ] Update creating-agents.md with auto-registration workflow
- [ ] Update using-agents.md with enhanced registry usage
- [ ] Create maintaining-infrastructure.md guide for discovery utilities

**Concepts**:
- [ ] Update hierarchical_agents.md with modular utility structure
- [ ] Update development-workflow.md with validation step

**Workflows**:
- [ ] Integrate hierarchical-agent-workflow.md into main navigation
- [ ] Create infrastructure-maintenance-workflow.md

**Utility Documentation**:
- [ ] Update .claude/lib/README.md with new modules and discovery utilities
- [ ] Create README sections for each new module
- [ ] Document backward compatibility wrappers

**Command Documentation**:
- [ ] Update commands/shared/README.md with complete index
- [ ] Document missing shared patterns (error-recovery, context-management, etc.)

### Documentation Standards

All documentation updates must follow:
- CommonMark markdown specification
- No emojis in file content
- Unicode box-drawing for diagrams (not ASCII art)
- Present-focused language (no historical markers like "New" or "Previously")
- Clear cross-references with relative links
- "See Also" sections for related content

## Dependencies

### External Dependencies
- None (pure internal refactoring)

### Internal Dependencies

**Phase Dependencies**:
- Phase 5 depends on Phase 1 (agent-discovery.sh pattern)
- Phase 5 depends on Phase 2 (modular utilities to validate)
- Phase 6 depends on Phases 1-5 (final integration testing)

**Utility Dependencies**:
- New discovery utilities depend on base-utils.sh (error handling, logging)
- Modular utilities depend on unified-logger.sh (consistent logging)
- Registry operations depend on existing JSON processing utilities

**Tool Dependencies**:
- jq (JSON processing) - already in use
- bash 4.0+ (associative arrays) - already required
- Standard Unix utilities (grep, find, sort) - available

## Risk Assessment and Mitigation

### High-Risk Areas

**Risk 1: Breaking Changes from Utility Splitting**
- **Impact**: High - Could break all commands using artifact-operations.sh
- **Probability**: Medium - Complex refactoring with many dependents
- **Mitigation**:
  - Maintain artifact-operations.sh as wrapper (backward compatibility)
  - Comprehensive regression testing before deployment
  - Phased rollout: utilities first, then update commands to use new modules directly

**Risk 2: Registry Schema Changes**
- **Impact**: Medium - Could break existing registry consumers
- **Probability**: Low - Only 2 consumers currently (limited impact)
- **Mitigation**:
  - Backward-compatible schema extension (add fields, don't remove)
  - Update agent-registry-utils.sh to handle both old and new schemas
  - Migration function to convert old format to new format

**Risk 3: Discovery Utility Accuracy**
- **Impact**: Medium - Inaccurate discovery could populate registries with wrong data
- **Probability**: Low - Controlled testing environment
- **Mitigation**:
  - Extensive testing with known agent/command inventory
  - Manual validation of initial discovery runs
  - Dry-run mode for all discovery utilities

### Medium-Risk Areas

**Risk 4: Documentation Navigation Changes**
- **Impact**: Low-Medium - Users may have bookmarked old paths
- **Probability**: Low - Internal navigation changes only
- **Mitigation**:
  - Maintain archive folder with redirects/notes
  - Update all cross-references in single phase
  - Validation utilities catch broken links

**Risk 5: Performance Overhead from Modularization**
- **Impact**: Low - Slightly slower sourcing times
- **Probability**: Medium - More files to source
- **Mitigation**:
  - Benchmark before/after performance
  - Consider creating bundle.sh if overhead significant
  - Commands can source specific modules instead of wrapper

### Low-Risk Areas

**Risk 6: Test Suite Expansion**
- **Impact**: Low - More tests to maintain
- **Probability**: High - Intentional expansion
- **Mitigation**: Automated test execution via run_all_tests.sh

## Notes

### Design Rationale

**Why split artifact-operations.sh?**
- 2,713 lines is difficult to maintain and navigate
- Logical separation improves discoverability (developers can find relevant functions faster)
- Focused modules enable better testing (unit tests per module)
- Reduces merge conflicts in collaborative development
- Enables selective sourcing (commands only load needed modules)

**Why enhance agent registry now?**
- Current 2/19 agent coverage is insufficient for meaningful metrics
- Discovery utilities need complete registry for validation
- Hierarchical agent workflows benefit from comprehensive tracking
- Foundation for future agent optimization and selection

**Why create discovery utilities?**
- Manual inventory is error-prone and outdated quickly
- Automated validation catches structural issues proactively
- Dependency mapping enables impact analysis for changes
- Supports future tooling (e.g., agent recommendation based on task type)

### Future Enhancements (Out of Scope)

**Not included in this refactoring** (potential future work):
- Pre-commit hooks for automatic validation (requires git hooks setup)
- Agent performance optimization based on registry metrics
- Command recommendation system based on task type
- Automated dependency update system
- Real-time registry updates during command execution
- Visual dependency graph rendering (currently text-based)
- Deprecation of backward compatibility wrappers (future major version)

### Backward Compatibility Commitment

**This refactoring guarantees**:
- All existing commands work without modification
- All existing agent workflows work without modification
- All existing utility sourcing patterns remain valid
- All existing tests pass without modification
- Zero breaking changes for users

**Backward compatibility mechanisms**:
- artifact-operations.sh wrapper sources all new modules
- Enhanced registry schema is backward-compatible (additive)
- Deprecated wrappers maintained for utility consolidations
- Documentation updates preserve existing links via redirects

### Expansion Strategy

**How to use /expand on this plan**:

Each phase is designed as a high-level overview. Use `/expand` to break down individual phases:

```bash
# Expand Phase 1 into detailed task breakdown
/expand-phase .claude/specs/plans/072_claude_infrastructure_refactoring.md 1

# Expand Phase 2 into detailed task breakdown
/expand-phase .claude/specs/plans/072_claude_infrastructure_refactoring.md 2

# And so on for each phase...
```

**Expected expansion results**:
- Phase 1: 8-12 detailed tasks (schema design, discovery implementation, registration, testing)
- Phase 2: 15-20 detailed tasks (dependency analysis, module extraction × 5, wrapper creation, testing)
- Phase 3: 6-10 detailed tasks (audit, creation, cleanup, validation)
- Phase 4: 5-8 detailed tasks (navigation updates, archive cleanup, validation)
- Phase 5: 12-18 detailed tasks (4 utilities × 3-4 tasks each, registry creation, testing)
- Phase 6: 8-12 detailed tasks (testing orchestration, documentation updates, performance benchmarking)

**Total estimated tasks after full expansion**: 54-80 detailed tasks across all 6 phases

### Success Metrics

**Quantitative Metrics**:
- Agent registry: 2/19 → 19/19 agents registered (100% coverage)
- artifact-operations.sh: 2,713 lines → 5 modules <1000 lines each
- Command shared docs: 10 files → 13-15 files (complete coverage)
- Documentation integration: +1 workflow doc, -8 archive references
- Discovery utilities: 0 → 4 new utilities
- Test coverage: 54 tests → 64-70 tests (new module + discovery tests)
- Dead references: [current count] → 0

**Qualitative Metrics**:
- Developer experience: Easier to find relevant utilities/agents
- Maintainability: Focused modules easier to update
- Reliability: Automated validation catches issues proactively
- Onboarding: Discovery utilities help new developers understand structure
- Confidence: Comprehensive testing ensures stability

---

**Plan created**: 2025-10-18
**Ready for**: Review and successive /expand expansion per phase
**Estimated total effort**: 3-5 days for complete implementation (after expansion and detailed planning)

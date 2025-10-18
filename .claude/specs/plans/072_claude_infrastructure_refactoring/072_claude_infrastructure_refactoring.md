# .claude/ Infrastructure Systematic Refactoring

## Plan Structure and Progress Tracking

### Hierarchy Overview

```
072_claude_infrastructure_refactoring/
├── 072_claude_infrastructure_refactoring.md (this file)
│
├── Phase 1: Agent Registry Foundation [PENDING]
│   ├── phase_1_agent_registry_foundation.md
│   ├── Stage 1: Enhanced Registry Schema Design [PENDING]
│   ├── Stage 2: Agent Discovery Implementation [PENDING]
│   ├── Stage 3: Schema Validation and Compliance [PENDING]
│   └── Stage 4: Testing and Documentation [PENDING]
│
├── Phase 2: Utility Modularization [PENDING]
│   ├── phase_2_utility_modularization/
│   │   ├── phase_2_utility_modularization.md
│   │   └── stage_1_dependency_analysis.md ✓ EXPANDED
│   ├── Stage 1: Dependency Analysis and Module Boundaries [PENDING]
│   ├── Stage 2: Module Extraction [PENDING]
│   ├── Stage 3: Backward Compatibility Wrapper [PENDING]
│   ├── Stage 4: Testing and Validation [PENDING]
│   └── Stage 5: Documentation Updates [PENDING]
│
├── Phase 3: Command Shared Documentation [PENDING]
│   ├── phase_3_command_shared_documentation.md
│   ├── Stage 1: Shared Reference Audit [PENDING]
│   ├── Stage 2: Missing Documentation Creation [PENDING]
│   ├── Stage 3: Additional Pattern Extraction [PENDING]
│   └── Stage 4: Validation Integration [PENDING]
│
├── Phase 4: Documentation Integration [PENDING]
│   ├── phase_4_documentation_integration.md
│   ├── Stage 1: Navigation Update [PENDING]
│   ├── Stage 2: Archive Cleanup [PENDING]
│   ├── Stage 3: Cross-Reference Validation [PENDING]
│   └── Stage 4: Optional Optimization [PENDING]
│
├── Phase 5: Discovery Infrastructure [PENDING]
│   ├── phase_5_discovery_infrastructure/
│   │   ├── phase_5_discovery_infrastructure.md
│   │   └── stage_3_dependency_mapping.md ✓ EXPANDED
│   ├── Stage 1: Command Discovery Implementation [PENDING]
│   ├── Stage 2: Structure Validation Implementation [PENDING]
│   ├── Stage 3: Dependency Mapping Implementation [PENDING]
│   ├── Stage 4: Registry Population and Management [PENDING]
│   └── Stage 5: Testing and Integration [PENDING]
│
└── Phase 6: Integration Testing [PENDING]
    ├── phase_6_integration_testing.md
    ├── Stage 1: Test Suite Execution [PENDING]
    ├── Stage 2: Backward Compatibility Validation [PENDING]
    ├── Stage 3: Performance Benchmarking [PENDING]
    ├── Stage 4: Documentation Review and Updates [PENDING]
    ├── Stage 5: Integration Smoke Tests [PENDING]
    └── Stage 6: Final Reporting [PENDING]
```

### Completion Status Summary

**Structure Level**: 2 (phases expanded + 2 stages expanded to separate files)

**Phase Status**: 0/6 phases completed
- ⬜ Phase 1: Agent Registry Foundation (12 tasks, 4 stages)
- ⬜ Phase 2: Utility Modularization (18 tasks, 5 stages) - **Stage 1 EXPANDED**
- ⬜ Phase 3: Command Shared Documentation (8 tasks, 4 stages)
- ⬜ Phase 4: Documentation Integration (6 tasks, 4 stages)
- ⬜ Phase 5: Discovery Infrastructure (12 tasks, 5 stages) - **Stage 3 EXPANDED**
- ⬜ Phase 6: Integration Testing (10 tasks, 6 stages)

**Stage Expansions**: 2/66 stages expanded to Level 2
- ✅ Phase 2, Stage 1: Dependency Analysis (400+ lines, comprehensive module boundary spec)
- ✅ Phase 5, Stage 3: Dependency Mapping (1287 lines, advanced graph algorithms)

**Total Tasks**: 66 detailed tasks across all phases

**Estimated Effort**: 3-5 days for complete implementation

### Quick Navigation

- **Main Plan**: [072_claude_infrastructure_refactoring.md](#) (this file)
- **Phase 1**: [Agent Registry Foundation](phase_1_agent_registry_foundation.md)
- **Phase 2**: [Utility Modularization](phase_2_utility_modularization/phase_2_utility_modularization.md)
  - [Stage 1: Dependency Analysis](phase_2_utility_modularization/stage_1_dependency_analysis.md) ✓
- **Phase 3**: [Command Shared Documentation](phase_3_command_shared_documentation.md)
- **Phase 4**: [Documentation Integration](phase_4_documentation_integration.md)
- **Phase 5**: [Discovery Infrastructure](phase_5_discovery_infrastructure/phase_5_discovery_infrastructure.md)
  - [Stage 3: Dependency Mapping](phase_5_discovery_infrastructure/stage_3_dependency_mapping.md) ✓
- **Phase 6**: [Integration Testing](phase_6_integration_testing.md)

### Implementation Waves

**Wave 1** (Parallel execution recommended):
- ⬜ Phase 1: Agent Registry Foundation
- ⬜ Phase 2: Utility Modularization (dependencies analyzed in Stage 1)
- ⬜ Phase 3: Command Shared Documentation
- ⬜ Phase 4: Documentation Integration

**Wave 2** (Sequential, after Wave 1):
- ⬜ Phase 5: Discovery Infrastructure (depends on Phase 1 pattern + Phase 2 validation targets)

**Wave 3** (Sequential, after Wave 2):
- ⬜ Phase 6: Integration Testing (validates all previous work)

---

## Design Vision Alignment

**This refactoring plan aims to bring the contents of `.claude/` into full alignment with the design vision documented in [`.claude/docs/README.md`](.claude/docs/README.md).**

The design vision establishes a hierarchical agent architecture where commands orchestrate specialized subagents through structured workflows, achieving 92-97% context reduction via metadata-only passing. The `.claude/` infrastructure is organized around:

- **Diataxis Documentation Framework**: Reference, Guides, Concepts, Workflows
- **Hierarchical Agent Coordination**: Multi-level supervision with metadata-based context passing
- **Topic-Based Artifact Organization**: Numbered topic directories (`specs/{NNN_topic}/`)
- **Command Workflow Chains**: Specialized subagents for research, planning, implementation, debugging
- **Modular Utility Architecture**: Focused utilities with clear separation of concerns

This refactoring systematically addresses gaps between current implementation and design vision, ensuring all components work cohesively within the documented architecture.

## Metadata
- **Date**: 2025-10-18
- **Feature**: Systematic refactoring of .claude/ commands and agents infrastructure
- **Scope**: Agent registry completion, utility modularization, documentation integration, discovery/validation systems
- **Structure Level**: 2 (phases expanded, Stage 3 of Phase 2 and Stage 3 of Phase 5 expanded to separate files)
- **Expanded Phases**: [1, 2, 3, 4, 5, 6]
- **Expanded Stages**:
  - Phase 2, Stage 1: Dependency Analysis and Module Boundary Definition
  - Phase 5, Stage 3: Dependency Mapping Implementation
- **Total Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Design Reference**: /home/benjamin/.config/.claude/docs/README.md
- **Research Reports**:
  - Internal research: Documentation structure analysis (41 files, Diataxis framework)
  - Internal research: Command architecture analysis (21 commands, 13,193 lines)
  - Internal research: Agent architecture analysis (19 agents + registry)
  - Internal research: Shared utilities analysis (44 libraries, 17,037 lines)

## Overview

This plan addresses systematic refactoring of the entire `.claude/` infrastructure based on comprehensive research findings across four domains: documentation, commands, agents, and shared utilities. The refactoring prioritizes completion of incomplete systems (agent registry at 2/19 agents), modularization of large consolidated utilities (artifact-operations.sh at 2,713 lines), integration of recent documentation changes, and creation of discovery/validation infrastructure.

**Alignment with Design Vision**: Each phase directly supports key architectural principles from `.claude/docs/README.md`:
- **Phase 1** (Agent Registry): Enables comprehensive agent tracking for hierarchical coordination
- **Phase 2** (Utility Modularization): Implements focused utilities with clear separation of concerns
- **Phase 3** (Shared Documentation): Completes reference-based composition pattern
- **Phase 4** (Documentation Integration): Maintains Diataxis framework integrity
- **Phase 5** (Discovery Infrastructure): Enables automated validation and maintenance
- **Phase 6** (Integration Testing): Validates alignment with architectural vision

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

**Note**: All phases have been expanded to Level 1 with detailed implementation specifications.

### Phase 1: Agent Registry Foundation and Discovery (Medium Complexity)
**Objective**: Complete agent registry infrastructure and auto-discovery system
**Status**: EXPANDED
**Dependencies**: None

**Summary**: Enhance agent registry schema to include type, category, tools, and dependencies metadata. Implement auto-discovery utility for scanning .claude/agents/ and registering all 19 agents. Create schema validation and frontmatter compliance checking.

**Key Deliverables**:
- Enhanced agent-registry.json with 8 metadata fields (was 4)
- agent-discovery.sh for auto-scanning and registration
- agent-schema-validator.sh for compliance checking
- 19/19 agents registered (was 2/19)
- Comprehensive test suite (test_agent_discovery.sh)

**For detailed tasks and implementation**, see [Phase 1: Agent Registry Foundation](phase_1_agent_registry_foundation.md)

---

### Phase 2: Utility Modularization - Split artifact-operations.sh (High Complexity)
**Objective**: Split 2,713-line artifact-operations.sh into focused modules with backward compatibility
**Status**: EXPANDED
**Dependencies**: None (independent refactoring)

**Summary**: Split large monolithic artifact-operations.sh into 5 focused modules: metadata-extraction.sh (~600 lines), hierarchical-agent-coordination.sh (~800 lines), context-pruning.sh (~500 lines), forward-message-patterns.sh (~400 lines), and artifact-registry.sh (~400 lines). Maintain backward compatibility via wrapper pattern.

**Key Deliverables**:
- 5 modular utilities (each <1000 lines)
- artifact-operations.sh wrapper for backward compatibility
- 6 new test suites (32-48 new tests)
- Zero breaking changes guaranteed
- Performance overhead <5%

**For detailed tasks and implementation**, see [Phase 2: Utility Modularization](phase_2_utility_modularization.md)

---

### Phase 3: Command Shared Documentation Completion (Low-Medium Complexity)
**Objective**: Audit and complete command shared documentation, remove dead references
**Status**: EXPANDED
**Dependencies**: None

**Summary**: Audit all command references to commands/shared/ files, create missing documentation (error-recovery.md, context-management.md, checkpoint-patterns.md), extract 3-5 additional common patterns, and integrate validation into structure-validator.sh to prevent future dead references.

**Key Deliverables**:
- 3-5 new shared documentation files (13-15 total)
- Zero dead references across all 21 commands
- Comprehensive commands/shared/README.md index
- structure-validator.sh integration for validation
- Audit report documenting all changes

**For detailed tasks and implementation**, see [Phase 3: Command Shared Documentation](phase_3_command_shared_documentation.md)

---

### Phase 4: Documentation Integration and Navigation Updates (Low Complexity)
**Objective**: Integrate hierarchical-agent-workflow.md and clean up archive references
**Status**: EXPANDED
**Dependencies**: None

**Summary**: Add hierarchical-agent-workflow.md to Workflows section in main README with cross-references from using-agents.md and hierarchical_agents.md. Remove all archive references from active documentation, create archive/README.md with historical context, and validate all internal links.

**Key Deliverables**:
- hierarchical-agent-workflow.md integrated with cross-references
- Zero archive references in active docs
- archive/README.md with comprehensive historical context
- validate-doc-links.sh utility for link validation
- All internal links verified and working

**For detailed tasks and implementation**, see [Phase 4: Documentation Integration](phase_4_documentation_integration.md)

---

### Phase 5: Discovery and Validation Infrastructure (Medium-High Complexity)
**Objective**: Create comprehensive discovery and validation utilities for ongoing maintenance
**Status**: EXPANDED
**Dependencies**: Phase 1 (agent-discovery.sh pattern), Phase 2 (modular utilities)

**Summary**: Create 4 discovery/validation utilities: command-discovery.sh for metadata extraction, structure-validator.sh for cross-reference checking, dependency-mapper.sh for dependency graphs, and registry management utilities. Implement command-metadata.json and utility-dependency-map.json registries.

**Key Deliverables**:
- 4 discovery utilities (~1,050 lines total code)
- command-metadata.json registry (all 21 commands)
- utility-dependency-map.json registry (all 44 utilities)
- Comprehensive test suite (25 new tests)
- Dependency graph visualization (Unicode box-drawing)
- Impact analysis capabilities

**For detailed tasks and implementation**, see [Phase 5: Discovery Infrastructure](phase_5_discovery_infrastructure.md)

---

### Phase 6: Integration Testing and Documentation Updates (Medium Complexity)
**Objective**: Comprehensive testing of all refactored components and documentation updates
**Status**: EXPANDED
**Dependencies**: Phases 1-5 (all previous phases must be complete)

**Summary**: Execute full test suite (54 existing + 25-35 new tests), perform end-to-end integration testing across all refactored components, validate zero breaking changes, update all documentation (reference, guides, concepts), and generate comprehensive refactoring summary report.

**Key Deliverables**:
- 100% test pass rate (79-89 total tests)
- Test execution report with coverage analysis
- Backward compatibility validation
- Performance benchmarks (<5% overhead)
- 10+ documentation updates (reference, guides, concepts, CLAUDE.md)
- Comprehensive refactoring summary report

**For detailed tasks and implementation**, see [Phase 6: Integration Testing](phase_6_integration_testing.md)

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

**Expansion Status**: ✅ COMPLETE - All 6 phases expanded to Level 1

Each phase has been expanded into a detailed specification file with comprehensive implementation guidance:

- **Phase 1**: [phase_1_agent_registry_foundation.md](phase_1_agent_registry_foundation.md) - 12 detailed tasks across 4 stages
- **Phase 2**: [phase_2_utility_modularization.md](phase_2_utility_modularization.md) - 18 detailed tasks across 5 stages
- **Phase 3**: [phase_3_command_shared_documentation.md](phase_3_command_shared_documentation.md) - 8 detailed tasks across 4 stages
- **Phase 4**: [phase_4_documentation_integration.md](phase_4_documentation_integration.md) - 6 detailed tasks across 4 stages
- **Phase 5**: [phase_5_discovery_infrastructure.md](phase_5_discovery_infrastructure.md) - 12 detailed tasks across 5 stages
- **Phase 6**: [phase_6_integration_testing.md](phase_6_integration_testing.md) - 10 detailed tasks across 6 stages

**Total detailed tasks**: 66 tasks across all phases

**Ready for Implementation**: Use `/implement` on individual phase files or the main plan for wave-based execution.

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
**Plan expanded**: 2025-10-18
**Last revised**: 2025-10-18
**Status**: ✅ All phases expanded to Level 1
**Ready for**: Implementation via `/implement` (wave-based or individual phases)
**Estimated total effort**: 3-5 days for complete implementation across all 6 phases

## Revision History

### 2025-10-18 - Revision 2: Plan Structure and Progress Tracking

**Changes Made**:
- Added comprehensive "Plan Structure and Progress Tracking" section at the top
- Included visual hierarchy tree showing all 6 phases and 25 stages
- Added completion status summary with checkboxes for tracking progress
- Included stage expansion status (2/66 stages expanded to Level 2)
- Added quick navigation links to all phase and expanded stage files
- Organized implementation waves for parallel execution guidance

**Reason for Revision**:
User requested the full structure of the plan be reflected at the top to easily keep track of what has been completed. This provides a single-view dashboard for the entire refactoring effort.

**New Sections Added**:
- Hierarchy Overview (ASCII tree showing all files and stages)
- Completion Status Summary (phase/stage tracking with checkboxes)
- Quick Navigation (direct links to all plan documents)
- Implementation Waves (parallel execution recommendations)

**Modified Sections**:
- Added 108-line "Plan Structure and Progress Tracking" section at beginning
- No changes to existing phase content or metadata
- Preserved all existing revision history

**Reports Used**: None (structural reorganization for better tracking)

**Impact**: Significantly improved plan navigability and progress tracking. No changes to implementation content. Users can now see the entire plan hierarchy and completion status at a glance.

---

### 2025-10-18 - Revision 1: Design Vision Alignment

**Changes Made**:
- Added "Design Vision Alignment" section at plan beginning
- Linked refactoring objectives to design vision in `.claude/docs/README.md`
- Added "Design Reference" to metadata
- Added phase-by-phase alignment description in Overview

**Reason for Revision**:
User requested explicit statement that the refactoring aims to align `.claude/` contents with the design vision documented in `.claude/docs/README.md`. This ensures all stakeholders understand the architectural principles guiding the refactoring.

**Key Architectural Principles Referenced**:
- Hierarchical agent architecture with 92-97% context reduction
- Diataxis documentation framework (Reference, Guides, Concepts, Workflows)
- Topic-based artifact organization (`specs/{NNN_topic}/`)
- Command workflow chains with specialized subagents
- Modular utility architecture with clear separation of concerns

**Modified Sections**:
- Added new "Design Vision Alignment" section (lines 3-15)
- Updated Metadata with "Design Reference" field
- Enhanced Overview with alignment mapping per phase

**Reports Used**: None (revision based on design vision documentation)

**Impact**: No changes to phase content or task breakdown. This revision provides strategic context and ensures implementation decisions align with documented architecture.

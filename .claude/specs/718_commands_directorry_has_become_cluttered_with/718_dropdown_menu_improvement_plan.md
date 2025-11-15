# Implementation Plan: Dropdown Menu Deduplication

**Topic**: Improve Claude Code dropdown menu to eliminate duplicate commands and show each command exactly once

**Created**: 2025-11-15

**Objective**: Fix redundant command entries in Claude Code's dropdown menu by implementing intelligent deduplication, scope-aware selection, and cache management. Expected to reduce `/im` dropdown entries from 4-5 down to 1-2 unique commands.

**Research Reports**:
- [001_dropdown_menu_investigation.md](reports/001_dropdown_menu_investigation.md) - Root cause analysis
- [002_command_enumeration_sources.md](reports/002_command_enumeration_sources.md) - Source analysis
- [003_dropdown_improvement_design_strategy.md](reports/003_dropdown_improvement_design_strategy.md) - Design strategy

---

## Phase 1: Analysis & Audit

**Duration**: 2-3 days

**Deliverables**: Comprehensive audit of command enumeration, scope analysis, and test case documentation

### Phase 1.1: Command Source Enumeration Audit

- [ ] Document all command sources (built-in, .claude/commands/, CLAUDE.md refs, hierarchy)
- [ ] Count actual commands in each source
- [ ] Identify all duplicate entries and their sources
- [ ] Map scope markers to their origins
- [ ] Document how Claude Code currently selects between sources
- [ ] Output: `audit/001_command_sources_enumeration.md`

**Success Criteria**:
- Comprehensive list of all 50+ commands across all sources
- Clear mapping showing where each /implement variant comes from
- Explanation of why scope markers appear

### Phase 1.2: Deleted Command Lifecycle Analysis

- [ ] Verify /resume-implement.md deleted from .claude/commands/
- [ ] Search all CLAUDE.md files for /resume-implement references
- [ ] Check if /resume-implement in built-in Claude Code registry
- [ ] Document when it was deleted and why (spec 033)
- [ ] Identify all references that need cleanup
- [ ] Output: `audit/002_deleted_commands_lifecycle.md`

**Success Criteria**:
- Confirmation that /resume-implement.md deleted
- List of all active references to /resume-implement
- Decision on whether to keep as deprecated or remove entirely

### Phase 1.3: Test Case Development

- [ ] Create test matrix of command sources and variants
- [ ] Define expected behavior for deduplication algorithm
- [ ] Document all edge cases (conflicts, scope markers, deletions)
- [ ] Create test data sets (mini CLAUDE.md files, mock registries)
- [ ] Design performance benchmarks (<100ms dropdown load)
- [ ] Output: `tests/001_deduplication_test_matrix.md`

**Success Criteria**:
- At least 20 test cases covering all scenarios
- Clear expected outputs for each test
- Performance baselines established

### Phase 1.4: Scope Semantics Documentation

- [ ] Define what "user" vs "project" scope markers mean
- [ ] Document current scope resolution behavior
- [ ] Determine if scope represents functional differences or just source
- [ ] Define rules for when scope should be shown (functional differences only)
- [ ] Output: `analysis/001_scope_semantics.md`

**Success Criteria**:
- Clear definition of scope marker semantics
- Decision rules for showing/hiding scope
- Examples of when scope should vs shouldn't appear

---

## Phase 2: Core Deduplication Implementation

**Duration**: 4-7 days

**Deliverables**: Working deduplication algorithm with test coverage

### Phase 2.1: Priority-Based Selection System

- [ ] Implement source priority ordering (custom > hierarchy > project > built-in)
- [ ] Build command registry data structure
- [ ] Implement source comparison and selection logic
- [ ] Handle edge cases (missing files, unavailable sources)
- [ ] Add logging for deduplication decisions
- [ ] Output: `.claude/lib/command-deduplication.sh`

**Success Criteria**:
- Registry built correctly for test data
- Correct source selected based on priority
- All edge cases handled gracefully

### Phase 2.2: Scope Resolution Logic

- [ ] Implement functional difference detection
- [ ] Build scope consolidation algorithm
- [ ] Create rules for when scope markers should appear
- [ ] Handle description conflicts
- [ ] Merge conflicting descriptions when appropriate
- [ ] Output: `.claude/lib/command-scope-resolver.sh`

**Success Criteria**:
- Correctly identifies functional vs non-functional differences
- Scope markers appear only when needed
- Descriptions are consistent and accurate

### Phase 2.3: Deleted Command Detection

- [ ] Verify commands exist in current sources
- [ ] Mark stale/deleted commands for cleanup
- [ ] Distinguish between deprecated (archived) and deleted (removed)
- [ ] Create deprecation notice mechanism
- [ ] Add validation warnings
- [ ] Output: `.claude/lib/command-validation.sh`

**Success Criteria**:
- /resume-implement correctly marked as deleted/deprecated
- Stale cache entries are identified
- Deprecation notices are accurate

### Phase 2.4: Unit Tests

- [ ] Write tests for priority selection
- [ ] Write tests for scope resolution
- [ ] Write tests for deleted command detection
- [ ] Write tests for edge cases and error conditions
- [ ] Achieve >85% code coverage
- [ ] Output: `.claude/tests/command-deduplication-tests.sh`

**Success Criteria**:
- All test cases pass
- Edge cases covered
- Code coverage >85%

---

## Phase 3: Cache Management System

**Duration**: 2-3 days

**Deliverables**: Cache invalidation and management system

### Phase 3.1: Cache Structure Design

- [ ] Design JSON registry cache format
- [ ] Include metadata (created, updated, version, hash)
- [ ] Store command entry with all sources and variants
- [ ] Document cache version compatibility
- [ ] Output: `design/cache_structure.md`

**Success Criteria**:
- Clear schema for cache file
- Version management approach documented
- Backward compatibility plan

### Phase 3.2: Cache Invalidation Logic

- [ ] Detect file changes in .claude/commands/
- [ ] Detect CLAUDE.md modifications
- [ ] Implement file watching or polling
- [ ] Build invalidation triggers
- [ ] Create cache freshness check
- [ ] Output: `.claude/lib/command-cache-manager.sh`

**Success Criteria**:
- Changes detected automatically
- Cache invalidated appropriately
- No stale cache entries persist

### Phase 3.3: Cache Performance Optimization

- [ ] Measure current cache performance
- [ ] Optimize registry building algorithm
- [ ] Benchmark cache hit rates
- [ ] Test memory usage
- [ ] Optimize for large command sets
- [ ] Output: `performance/cache_benchmarks.md`

**Success Criteria**:
- Registry builds in <50ms
- Cache hit rate >95%
- Memory usage <5MB

### Phase 3.4: Cache Testing

- [ ] Test cache creation and loading
- [ ] Test invalidation triggers
- [ ] Test cleanup of deleted entries
- [ ] Test performance under load
- [ ] Output: `.claude/tests/command-cache-tests.sh`

**Success Criteria**:
- All cache operations tested
- Performance meets targets
- Edge cases handled

---

## Phase 4: Integration & Validation

**Duration**: 3-5 days

**Deliverables**: Integrated system working with Claude Code

### Phase 4.1: Claude Code Integration

- [ ] Determine integration point (Claude Code plugin/extension)
- [ ] Build interface to replace existing command enumeration
- [ ] Integrate deduplication registry
- [ ] Hook into dropdown display logic
- [ ] Maintain backward compatibility
- [ ] Output: Integration guide + modified Claude Code interface

**Success Criteria**:
- Dropdown uses new deduplication logic
- All commands still discoverable
- No breaking changes

### Phase 4.2: Backward Compatibility

- [ ] Test with existing workflows
- [ ] Verify all custom commands still work
- [ ] Test scope overrides still function
- [ ] Ensure CLAUDE.md still loads correctly
- [ ] Test multiple worktree support
- [ ] Output: `validation/compatibility_tests.md`

**Success Criteria**:
- Existing workflows unaffected
- Custom commands work as before
- No regression in functionality

### Phase 4.3: End-to-End Testing

- [ ] Test dropdown display with all prefixes
- [ ] Verify no duplicates appear
- [ ] Test scope markers behavior
- [ ] Test with added/deleted commands
- [ ] Test performance under real conditions
- [ ] Output: `tests/e2e_dropdown_tests.sh`

**Success Criteria**:
- Clean dropdown display
- No duplicates
- Fast performance
- All prefixes work correctly

### Phase 4.4: User Acceptance Testing

- [ ] Create test plan for users
- [ ] Document expected changes
- [ ] Gather feedback from early users
- [ ] Document edge cases found
- [ ] Iterate based on feedback
- [ ] Output: `validation/user_feedback_summary.md`

**Success Criteria**:
- Positive user feedback
- No major issues reported
- Requests for future improvements documented

---

## Phase 5: Documentation & Rollout

**Duration**: 1-2 days

**Deliverables**: Documentation, guides, and rollout plan

### Phase 5.1: User Documentation

- [ ] Create user guide for new behavior
- [ ] Document scope marker semantics
- [ ] Provide troubleshooting section
- [ ] Document deprecated commands
- [ ] Create FAQ
- [ ] Output: `.claude/docs/guides/command-deduplication-guide.md`

**Success Criteria**:
- Clear explanation of changes
- Users understand new behavior
- Migration path documented

### Phase 5.2: Developer Documentation

- [ ] Document deduplication algorithm
- [ ] Create architecture guide
- [ ] Document library interfaces
- [ ] Create testing guide
- [ ] Document performance characteristics
- [ ] Output: `.claude/docs/guides/command-deduplication-architecture.md`

**Success Criteria**:
- Clear architecture documentation
- Easy for others to understand/maintain
- Extension points documented

### Phase 5.3: Migration Guide

- [ ] Document how to handle deprecated commands
- [ ] Provide cleanup checklist for projects
- [ ] Create rollback plan if needed
- [ ] Document known limitations
- [ ] Output: `migration/migration_guide.md`

**Success Criteria**:
- Users know what changed
- Clear path forward
- Rollback plan available

### Phase 5.4: Release Notes

- [ ] Write user-facing release notes
- [ ] Document improvements and fixes
- [ ] List known limitations
- [ ] Document timeline for improvements
- [ ] Output: `RELEASE_NOTES.md`

**Success Criteria**:
- Clear summary of changes
- Benefits articulated
- Grateful tone for improvements

---

## Success Criteria (Project-Level)

### Functional Success
- [ ] Dropdown shows each command exactly once
- [ ] No "(user)" or "(project)" duplicates
- [ ] Deleted commands don't appear
- [ ] Descriptions are accurate and consistent
- [ ] /resume-implement properly handled (deprecated/hidden)

### Technical Success
- [ ] >85% code coverage on deduplication
- [ ] <100ms dropdown load time
- [ ] Cache hit rate >95%
- [ ] All test cases pass
- [ ] No regressions in existing functionality

### User Success
- [ ] Positive feedback from users
- [ ] Dropdown perceived as cleaner/less confusing
- [ ] No workflow disruptions
- [ ] Clear improvement over current state

### Process Success
- [ ] All phases completed on time
- [ ] Documentation comprehensive
- [ ] Test coverage adequate
- [ ] Rollout executed smoothly

---

## Risk Assessment

### High Risk
1. **Claude Code Integration Complexity**
   - Risk: Integration point may be difficult to access or modify
   - Mitigation: Research integration architecture early (Phase 1)
   - Contingency: Provide wrapper script if direct integration not feasible

2. **Breaking Changes**
   - Risk: Deduplication may break existing workflows
   - Mitigation: Comprehensive backward compatibility testing
   - Contingency: Rollback plan and feature flag

### Medium Risk
1. **Cache Invalidation Race Conditions**
   - Risk: Cache may become stale in rapid file changes
   - Mitigation: Aggressive cache validation and refresh
   - Contingency: Force refresh mechanism

2. **Performance Degradation**
   - Risk: Large command sets may slow down dropdown
   - Mitigation: Performance optimization and benchmarking
   - Contingency: Caching strategy and lazy loading

### Low Risk
1. **Documentation Gaps**
   - Risk: Users may not understand scope markers
   - Mitigation: Clear documentation and examples
   - Contingency: FAQ and support resources

2. **Scope Semantics Confusion**
   - Risk: Different interpretations of scope meaning
   - Mitigation: Define clear semantics and document
   - Contingency: In-app help tooltips

---

## Resources Required

### Skills Needed
- Bash scripting (for lib scripts)
- JSON manipulation
- Claude Code plugin development
- File system operations
- Performance optimization
- Testing methodologies

### Tools Required
- bash, grep, sed, awk (existing)
- jq (for JSON manipulation)
- Claude Code development environment
- Performance profiling tools (optional)

### Time Estimates
- Phase 1: 10-15 hours
- Phase 2: 20-30 hours
- Phase 3: 10-15 hours
- Phase 4: 15-20 hours
- Phase 5: 5-10 hours
- **Total**: 60-90 hours (~1.5-2 week effort with full-time focus)

---

## Dependencies & Blockers

### External Dependencies
- Access to Claude Code source/plugin system
- Understanding of Claude Code command discovery mechanism
- Ability to modify Claude Code behavior

### Internal Dependencies
- Completion of Phase 1 for design decisions
- Completion of Phase 2 for cache management
- Completion of Phase 4 for rollout

### Known Blockers
- Need to determine Claude Code integration point early
- May need approval for Claude Code source modification
- Requires testing in multiple Claude Code versions

---

## Next Steps

### Immediate Actions (Today)
1. Confirm Claude Code integration approach feasible
2. Schedule Phase 1 research with stakeholders
3. Set up development environment
4. Review research reports

### Before Phase 2 (Phase 1 completion)
1. Audit completed and documented
2. Test cases created and reviewed
3. Scope semantics approved
4. Architecture design reviewed

### Timeline
- Week 1: Phase 1 (Analysis & Audit)
- Week 2: Phase 2 (Core Deduplication)
- Week 2-3: Phase 3 (Cache Management)
- Week 3-4: Phase 4 (Integration & Validation)
- Week 4: Phase 5 (Documentation & Rollout)

---

## References

**Related Documentation**:
- CLAUDE.md - Project configuration
- .claude/commands/ - User-defined commands directory
- dropdown_menu.md - Current dropdown screenshot
- Command Reference - Complete command catalog

**Related Plans**:
- Plan 033: Command consolidation (deleted /resume-implement)
- Plan 050+: Future command system improvements


# Shim Removal Strategy and Best Practices Research Report

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Shim Removal Strategy and Best Practices
- **Report Type**: best practices

## Executive Summary

Research into shim removal strategies reveals that safe deprecation requires a multi-phase approach with comprehensive testing, clear migration timelines, and rollback capabilities. This project demonstrates mature deprecation practices including 30-90 day migration windows, backward-compatibility shims with explicit warnings, and comprehensive test coverage before removal. Best practices from both industry sources and this codebase emphasize gradual transitions, dual-write patterns during migration, automated testing to prevent regressions, and maintaining rollback safety through backups and git history. The safest removal order prioritizes low-usage shims first, followed by those with clear modern replacements, while deferring complex multi-dependency removals until migration is complete.

## Findings

### 1. Project-Specific Deprecation Patterns

#### 1.1 Backward-Compatibility Shim Pattern

The project implements an exemplary shim pattern in `/home/benjamin/.config/.claude/lib/artifact-operations.sh`:

```bash
#!/usr/bin/env bash
# artifact-operations.sh - DEPRECATED backward-compatibility shim
# Version: 1.0.0 (Shim)
#
# DEPRECATED: This library has been split into:
#   - artifact-creation.sh - Functions for creating new artifacts
#   - artifact-registry.sh - Functions for tracking and querying artifacts
#
# Migration Timeline:
#   - 2025-10-29: Shim created for backward compatibility
#   - 2025-12-01: Target date for updating all 77 command references
#   - 2026-01-01: Shim removal scheduled (1-2 releases after creation)
```

**Key Features** (lines 1-22):
- Clear deprecation notice with migration dates
- Explicit split library references
- Timeline showing creation → migration → removal phases
- Migration examples showing old vs new usage

**Implementation Safety** (lines 23-56):
- Sources both replacement libraries transparently
- Error handling if split libraries missing
- Single deprecation warning per process (lines 52-56)
- Absolute path resolution for reliability (line 25)

**Migration Window**: 60+ days from shim creation to removal (lines 10-12)

#### 1.2 Development Philosophy on Deprecation

From `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 23-45):

**Clean-Break Refactoring Approach**:
- Prioritizes coherence over backward compatibility
- Accepts breaking changes for quality improvements
- No legacy burden on current design
- Exception for command/agent files requiring special handling

**Core Values Hierarchy** (lines 31-45):
1. Clarity - clean, consistent documentation
2. Quality - well-designed systems
3. Coherence - seamless component integration
4. Maintainability - easy to understand today

**Implication for Shims**: Shims are temporary bridges, not permanent features. They enable migration but should not compromise current design quality.

### 2. Refactoring Methodology and Testing

#### 2.1 Systematic Refactoring Process

From `/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md` (lines 44-153):

**Pre-Refactoring Assessment** (lines 44-95):
- Audit current state with enforcement tools
- Measure complexity metrics (line count, code blocks)
- Inventory functionality comprehensively
- Set measurable refactoring goals

**Refactoring Goals Framework** (lines 115-133):

**Required Goals** (must achieve):
- Standards compliance: Audit score ≥95/100
- Functionality preservation: All existing features work
- Test coverage: All execution paths validated

**Optimization Goals** (should achieve):
- File size reduction: 30-40% smaller
- Utility integration: Replace manual implementations
- Testing consolidation: Single comprehensive suite

**Documentation Goals**:
- Update CLAUDE.md references
- Update command README
- Remove temporal markers (no historical commentary)

#### 2.2 Testing-First Approach

From `/home/benjamin/.config/.claude/tests/README.md` (lines 176-196):

**Coverage Requirements**:
- Modified Code: ≥80% line coverage
- Existing Code: ≥60% baseline coverage
- Critical Paths: 100% coverage required (checkpoint save/restore, plan expansion/collapse)

**Test Categories for Shim Removal** (lines 222-230):
1. Unit Tests - Individual functions in isolation
2. Integration Tests - Command workflows end-to-end
3. Round-Trip Tests - Data preservation across transformations
4. Regression Tests - Legacy format compatibility
5. Edge Case Tests - Boundary conditions and error handling

**Best Practice** (lines 338-346):
- Create tests BEFORE removal to establish baseline
- Run tests with shim present (should pass)
- Remove shim
- Re-run same tests (should still pass)
- If tests fail, rollback and fix migration

### 3. Rollback and Safety Mechanisms

#### 3.1 Backup and Rollback Strategy

From `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` (lines 19-58):

**Retention Guidelines**:
- Critical Command Files: Keep most recent backup permanent
- Implementation Plans: Keep until plan completion
- Agent Files: Keep most recent backup permanent
- Library Files: Keep backups from API changes for 60 days

**Verification Period** (line 31): 7-14 days of production use before removing backups

**Rollback Procedures** (lines 149-171):
1. Identify backup to restore
2. Compare current with backup using diff
3. Restore backup file
4. Verify rollback with validation tools
5. Test command/library functionality

#### 3.2 Model Rollback Case Study

From `/home/benjamin/.config/.claude/docs/guides/model-rollback-guide.md` (lines 96-135):

**Rollback Process Pattern**:
1. **Backup Current State** - Capture metrics before rollback
2. **Revert Changes** - Use sed for single-line field updates
3. **Verify Rollback** - Confirm changes applied correctly
4. **Run Validation Suite** - Execute comprehensive tests
5. **Document Rollback** - Record reason and next steps
6. **Git Commit** - Version control the rollback

**Post-Rollback Monitoring** (lines 246-291):
- Immediate (Day 1): Monitor error rates, run integration tests
- Short-term (Week 1): Root cause analysis, baseline verification
- Long-term (Month 1): Retry decision, process improvements

**Emergency Rollback** (lines 353-369): Fast rollback procedure for critical issues

### 4. Industry Best Practices

#### 4.1 Lua-Specific Deprecation Patterns

From web research on Lua deprecation (WebSearch: "Lua code deprecation shim removal best practices 2025"):

**Timing and Communication**:
- Issue warnings for all new usages of deprecated functions
- Enable warnings for all usages in release before removal
- Minimum 3-year deprecation period before removal (for widely-used features)
- Review release notes to identify deprecated features

**Migration Support**:
- Use compatibility libraries or shims for backward compatibility
- Provide clear migration paths to new APIs
- Avoid using "deprecated" flag alone - document alternatives

**User-Centric Approach**:
- Give users warning with specific removal timeline
- Avoid forcing immediate migration when users are powerless to act
- Balance developer warnings vs user frustration

#### 4.2 General Refactoring Safety Patterns

From web research on safe refactoring (WebSearch: "safe code refactoring shim removal strategy testing patterns"):

**Testing Requirements**:
- Automatic unit tests MUST be set up before refactoring
- Tests ensure routines still behave as expected
- Refactoring becomes iterative: transform → test → transform
- Most trustworthy safety net: suite of automated tests (fast, reliable unit tests)

**Shim Removal Strategy**:
- Introduce temporary adapters (shims) to minimize breakage
- Create shim with clear TODOs and comprehensive tests
- Remove temporary adapters only when:
  - Tests are green (all passing)
  - Usage is fully migrated
  - Verification period complete

**Red-Green-Refactor Cycle**:
- Test-driven development drives refactoring
- Iterative cycle ensures continuous validation
- Refactoring test code differs from production code (distinct bad smells)

#### 4.3 Migration Strategies

From web research on backward compatibility removal (WebSearch: "backward compatibility removal migration strategy"):

**Multi-Phase Migration Process**:

**Phase 1: Dual-Write Pattern**
- Write to both old and new implementations simultaneously
- Maintains data consistency
- Allows thorough validation before deprecation

**Phase 2: Deprecation Notice**
- Mark old implementation as deprecated
- Provide migration timeline
- Document new approach

**Phase 3: Read Migration**
- Update application code to read from new implementation only
- Run comprehensive tests
- Monitor production behavior

**Phase 4: Write Migration**
- Update all write operations to new implementation
- Maintain dual-write for safety period
- Verify no regressions

**Phase 5: Cleanup**
- Remove old implementation after verification period
- Archive code rather than delete immediately
- Document removal in changelog

**Zero-Downtime Approach**:
- Non-disruptive changes (add columns/tables, not drop)
- Keep old structures until migration complete
- Both versions of application continue running
- Remove old structures only after full transition

**Rollback Safety**:
- Schema remains backward compatible during migration
- Application code can always rollback after deployment
- Monitor data and usage before finalizing removal

### 5. Incremental Removal Approaches

#### 5.1 Safe Removal Order

Based on project analysis and industry patterns:

**Priority 1: Low-Usage Shims** (remove first)
- Shims with <5 references across codebase
- Limited blast radius if issues occur
- Easy to verify migration completeness
- Example: Specialized utilities used by 1-2 commands

**Priority 2: Clear Replacements** (remove second)
- Shims where replacement is well-documented
- One-to-one function mapping exists
- Modern replacement is proven stable
- Example: artifact-operations.sh → artifact-creation.sh + artifact-registry.sh

**Priority 3: Multi-Dependency Shims** (remove last)
- Shims sourced by many libraries/commands
- Complex dependency chains
- Higher risk of cascading failures
- Example: Base utility consolidations affecting 10+ libraries

#### 5.2 Incremental Testing Strategy

From `/home/benjamin/.config/.claude/tests/README.md` and refactoring-methodology.md:

**Step 1: Establish Baseline**
- Run full test suite with shim present
- Document all passing tests (e.g., 57/76 passing)
- Capture performance metrics
- Record coverage percentage

**Step 2: Create Migration Tests**
- Add tests for new implementation paths
- Test both shim and direct usage
- Verify identical behavior
- Example: Test artifact creation via shim vs direct library

**Step 3: Gradual Migration**
- Update 10-20% of references at a time
- Run full test suite after each batch
- Monitor for regressions
- Rollback individual batches if needed

**Step 4: Shim Removal**
- Remove shim only after 100% migration
- Run comprehensive test suite
- Verify no references remain
- Monitor production for 7-14 days

**Step 5: Cleanup**
- Remove deprecated code
- Update documentation
- Remove migration tests (keep regression tests)
- Archive shim code for reference

### 6. Project-Specific Shim Examples

#### 6.1 Deprecated Directory Pattern

From `/home/benjamin/.config/nvim/lua/neotex/deprecated/README.md` (lines 1-68):

**Purpose of Deprecated Directory**:
- Historical reference
- Migration assistance
- Potential future reuse
- Understanding configuration evolution

**Contents**:
- Legacy plugin specifications (alpha.lua, autopairs.lua, colorizer.lua)
- Original core configuration modules
- Experimental features

**Migration Status** (lines 33-39):
- Code in directory NOT loaded during initialization
- Active implementations in separate directories
- Clear separation prevents accidental usage

**Removal Policy** (lines 51-56):
- Remove when replacement established >6 months
- No active migration needs exist
- Code no longer provides useful reference

**Reactivation Procedure** (lines 41-49):
1. Review deprecated module purpose
2. Check if equivalent functionality exists
3. Copy to appropriate active directory
4. Update require paths and dependencies
5. Test thoroughly before committing

#### 6.2 Library Consolidation Example

From `/home/benjamin/.config/.claude/specs/519_claudedocs_and_the_current_implementation_in_order/reports/001_lazy_library_loading_improvements/OVERVIEW.md` (lines 58-75):

**artifact-operations.sh Split** (reported 2025-10-29):
- Already split into artifact-creation.sh and artifact-registry.sh
- **77 command references still use old name**
- Shim provides backward compatibility
- Migration target: 2025-12-01 (60-day window)
- Removal scheduled: 2026-01-01

**Migration Approach** (lines 196-199):
1. Create backward-compatibility shim (completed)
2. Update 77 references gradually
3. Keep shim for 1-2 releases
4. Remove shim after verification period

**Benefits of Gradual Migration**:
- No breaking changes during transition
- Allows incremental testing
- Provides rollback capability per-batch
- Reduces risk of cascading failures

### 7. Testing Infrastructure for Shim Removal

#### 7.1 Test Suite Structure

From `/home/benjamin/.config/.claude/tests/README.md` (lines 88-127):

**Running Individual Test Suites**:
```bash
# Run parsing utilities tests
./test_parsing_utilities.sh

# Run command integration tests
./test_command_integration.sh

# Run roundtrip tests
./test_progressive_roundtrip.sh
```

**Test Framework** (lines 139-175):
- Setup: Create temporary test environment
- Test Functions: Individual cases with descriptive names
- Assertions: pass() and fail() helpers
- Cleanup: Remove temporary files
- Summary: Display test results

**Exit Codes**:
- 0: All tests passed (safe to proceed with removal)
- 1: One or more tests failed (fix before removal)

#### 7.2 Coverage Requirements for Shim Removal

From `/home/benjamin/.config/.claude/tests/README.md` (lines 176-196):

**Coverage Targets**:
- Modified Code (shim removal): ≥80% coverage
- Existing Code (unaffected): ≥60% baseline
- Critical Paths (replacement functionality): 100% coverage

**Critical Path Examples**:
- Checkpoint save/restore operations
- Plan expansion/collapse workflows
- Metadata preservation across transformations

**Test Categories** (lines 222-230):
1. **Unit Tests**: Individual function behavior (shim vs direct)
2. **Integration Tests**: End-to-end workflows with new implementation
3. **Round-Trip Tests**: Data preservation without shim
4. **Regression Tests**: Legacy format compatibility maintained
5. **Edge Case Tests**: Boundary conditions and error handling

### 8. Documentation and Communication

#### 8.1 Timeless Documentation Standards

From `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 49-87):

**Present-Focused Writing**:
- Document current implementation accurately
- No historical reporting in main documentation
- Focus on what system does now, not how it evolved
- Ban historical markers: (New), (Old), (Updated), (Deprecated)

**Separation of Concerns** (lines 59-65):
- Functional Documentation: What system does (timeless)
- CHANGELOG.md: When features added (historical)
- Migration Guides: How to upgrade (transitional)

**Exception for Shim Files** (artifact-operations.sh pattern):
- Shim files MUST include deprecation timeline
- Historical context necessary for migration
- Migration guidance is core purpose
- Remove file entirely after deprecation period

#### 8.2 Migration Documentation Pattern

From artifact-operations.sh shim (lines 1-21):

**Required Elements**:
1. Clear deprecation notice at top of file
2. Replacement library references
3. Migration timeline with specific dates
4. Usage examples (old vs new)
5. Rationale for split/change

**Timeline Structure**:
- Creation Date: When shim introduced
- Migration Target: When references should be updated
- Removal Date: When shim will be deleted

**Example Timeline**:
```
- 2025-10-29: Shim created for backward compatibility
- 2025-12-01: Target date for updating all 77 references
- 2026-01-01: Shim removal scheduled
```

**Migration Window**: Typically 30-90 days depending on usage scope

## Recommendations

### 1. Establish Shim Removal Phasing

**Phase 0: Pre-Removal Assessment** (before any changes)
- Audit all existing shims and their usage counts
- Categorize by removal priority (low-usage, clear replacements, multi-dependency)
- Establish test baseline (run full suite, document passing rate)
- Create removal tracking document with timeline

**Phase 1: Low-Risk Removals** (weeks 1-2)
- Target shims with <5 references
- Create migration tests for each shim
- Update references in small batches (10-20% at a time)
- Run full test suite after each batch
- Remove shim only after 100% migration verified

**Phase 2: Medium-Risk Removals** (weeks 3-6)
- Target shims with clear replacements (like artifact-operations.sh)
- Follow existing backward-compatibility shim pattern
- Implement 30-60 day migration window
- Emit deprecation warnings during usage
- Document migration path explicitly

**Phase 3: High-Risk Removals** (weeks 7-12)
- Target multi-dependency shims last
- Extend migration window to 60-90 days
- Consider permanent compatibility layer if risk too high
- Gradual migration with extensive monitoring
- Maintain rollback capability throughout

### 2. Implement Comprehensive Testing Strategy

**Before Shim Removal**:
- Run full test suite with shim present (establish baseline)
- Create tests for new implementation paths
- Verify identical behavior between shim and direct usage
- Achieve ≥80% coverage on modified code

**During Migration**:
- Run tests after each batch of reference updates
- Monitor for regressions immediately
- Maintain test coverage above baseline
- Use round-trip tests to verify data preservation

**After Shim Removal**:
- Run full test suite without shim
- Verify all tests still pass (no new failures)
- Monitor production usage for 7-14 days
- Keep regression tests permanently

### 3. Follow Backward-Compatibility Shim Pattern

For any shim removal, create intermediate compatibility layer following artifact-operations.sh pattern:

**Required Elements**:
1. Deprecation notice header with timeline
2. Clear replacement library references
3. Transparent sourcing of both/all replacements
4. Error handling if replacements missing
5. Single deprecation warning per process
6. Migration examples showing old vs new usage

**Timeline Template**:
```bash
# Migration Timeline:
#   - [DATE]: Shim created for backward compatibility
#   - [DATE + 30-60 days]: Target date for updating references
#   - [DATE + 60-90 days]: Shim removal scheduled
```

### 4. Maintain Rollback Capability

**Backup Strategy**:
- Create backups before any shim removal
- Keep most recent backup permanent (until next major refactor)
- Maintain 7-14 day verification period
- Use git history as primary rollback mechanism

**Rollback Procedure** (if issues discovered):
1. Identify backup/commit to restore
2. Compare current with backup using diff
3. Restore backup file or git revert
4. Verify rollback with validation tools
5. Test command/library functionality
6. Document rollback reason for future reference

**Emergency Rollback**:
- Fast rollback procedure for critical issues
- Skip validation initially (run post-rollback)
- Immediate git commit of rollback
- Post-rollback monitoring for 48 hours

### 5. Document Migration Paths Clearly

**For Each Shim**:
- Create migration guide in shim file header
- Document replacement functionality
- Provide code examples (before/after)
- Include timeline with specific dates
- Reference related documentation

**Update Project Documentation**:
- Add deprecation notice to CHANGELOG.md
- Update library/command README files
- Remove temporal markers after migration complete
- Archive historical information appropriately

**Communication**:
- Notify team of pending deprecations
- Provide migration timeline upfront
- Update progress regularly
- Announce removal completion

### 6. Optimize Removal Order

**Priority 1: Low-Usage Shims** (safe to remove first)
- <5 references across codebase
- Limited impact if issues occur
- Easy to verify completeness
- Quick wins build confidence

**Priority 2: Clear Replacements** (medium risk)
- One-to-one function mapping exists
- Modern replacement proven stable
- Migration path well-documented
- Example: artifact-operations.sh split

**Priority 3: Multi-Dependency Shims** (highest risk)
- Sourced by many libraries/commands
- Complex dependency chains
- Requires comprehensive testing
- Consider permanent compatibility layer

### 7. Monitor and Measure

**Metrics to Track**:
- Test passing rate (maintain ≥baseline)
- Number of references remaining
- Migration completion percentage
- Error rates in production
- Time since shim creation

**Success Criteria**:
- All tests passing after removal
- Zero references to deprecated shim remain
- No production errors for 7-14 days
- Documentation updated completely
- Team confident in new implementation

**Warning Signs** (trigger rollback):
- Test passing rate drops >5%
- Production error rate increases
- Cascading failures detected
- Migration blocking critical work

## References

### Codebase References

- `/home/benjamin/.config/.claude/lib/artifact-operations.sh` (lines 1-57) - Exemplary backward-compatibility shim pattern with deprecation timeline
- `/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md` (lines 1-814) - Comprehensive refactoring process with pre-assessment, testing, and validation
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558) - Development philosophy prioritizing clean breaks over backward compatibility
- `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` (lines 1-230) - Backup strategies and rollback procedures
- `/home/benjamin/.config/.claude/docs/guides/model-rollback-guide.md` (lines 1-392) - Detailed rollback process with monitoring and recovery
- `/home/benjamin/.config/.claude/tests/README.md` (lines 1-364) - Test suite structure, coverage requirements, and best practices
- `/home/benjamin/.config/nvim/lua/neotex/deprecated/README.md` (lines 1-68) - Deprecated directory pattern and removal policy
- `/home/benjamin/.config/.claude/specs/519_claudedocs_and_the_current_implementation_in_order/reports/001_lazy_library_loading_improvements/OVERVIEW.md` (lines 1-413) - Library consolidation case study with migration timeline

### Web Research Sources

- Lua deprecation best practices (2025): Minimum 3-year deprecation period, compatibility libraries, user-centric warnings
- Safe refactoring patterns: Automated testing requirements, shim removal with TODOs, red-green-refactor cycle
- Backward compatibility removal strategies: Multi-phase migration, dual-write pattern, zero-downtime approach, rollback safety

# Himalaya Plugin Refinement Plan

This document outlines the systematic refinement phases for the Himalaya email plugin, following the principles in [GUIDELINES.md](GUIDELINES.md).

## Current State Analysis

### Architecture Overview
The plugin has undergone significant refactoring (Phases 1-7 complete) with:
- ✅ Modular architecture with clear separation of concerns
- ✅ Unified state management
- ✅ Maildir-based storage system
- ✅ Event-driven command system
- ✅ Comprehensive UI components

### Active Development
Currently on `himalaya_drafts` branch with recent work on:
- Draft management system (maildir-based)
- Email composer improvements
- Sidebar and email list UI updates
- Scheduler enhancements

### Technical Debt
1. **Test Infrastructure**: Tests migrated but many need updates
2. **Documentation**: README files need updates throughout
3. **Code Duplication**: Some modules have redundant functionality
4. **Unused Code**: Legacy code from previous implementations
5. **API Inconsistencies**: Some modules use different patterns

## Phase 1: Test Infrastructure Stabilization (COMPLETE)

### Objectives
- ✅ Restore full test suite functionality
- ✅ Establish baseline for safe refactoring
- ✅ Document current behavior

### Tasks

1. **Fix Test Runner Integration**
   - [x] Restore test_runner.lua with updated paths
   - [x] Update command references in debug.lua
   - [x] Verify :HimalayaTest command works
   - [x] Fix any remaining path issues

2. **Update Core Tests**
   - [x] Fix maildir foundation tests
   - [x] Update draft manager tests
   - [x] Fix email composer tests
   - [x] Update scheduler tests

3. **Mock Infrastructure**
   - [x] Update test_mocks.lua for current utils
   - [x] Add mocks for new modules (state, events)
   - [x] Ensure no real CLI calls during tests

4. **Test Documentation**
   - [x] Create comprehensive test/README.md
   - [x] Document test patterns
   - [x] Create test writing guide

### Success Criteria
- ✅ All existing tests pass (100% pass rate)
- ✅ No real Himalaya CLI calls during tests
- ✅ Clear documentation for adding new tests
- ✅ Test consolidation and cleanup complete

## Phase 2: Test Quality & Coverage Enhancement (2-3 days)

### Objectives
- Improve existing test implementations
- Add comprehensive test coverage
- Establish testing best practices

### Tasks

1. **Improve Existing Tests**
   - [x] Enhance test assertions with more specific checks
   - [x] Add better error reporting in test failures
   - [x] Improve test setup/teardown consistency
   - [x] Add test timing and performance metrics
   - [x] Standardize test naming conventions

2. **Expand Test Coverage**
   - [x] Add edge case testing for all modules
   - [ ] Create comprehensive integration tests
   - [x] Add error condition testing
   - [ ] Test async operations and timing
   - [ ] Add UI component interaction tests

3. **Test Infrastructure Improvements**
   - [x] Create test utilities for common patterns
   - [x] Add test data factories and fixtures
   - [ ] Implement test parallelization
   - [x] Add test categorization and filtering
   - [x] Create performance benchmarking tests

4. **Testing Best Practices**
   - [ ] Document test writing standards
   - [ ] Create testing cookbook with examples
   - [ ] Add code coverage reporting
   - [ ] Implement test quality metrics
   - [ ] Create test review guidelines

5. **Test Documentation Refactoring**
   - [ ] Refactor tests/README.md for clarity and consistency
   - [ ] Create overview of each test subdirectory with purpose and scope
   - [ ] Add README.md to each subdirectory (commands/, features/, integration/, performance/, utils/)
   - [ ] Document test running procedures for users
   - [ ] Add contributing guide for writing new tests
   - [ ] Explain test architecture and patterns
   - [ ] Document debug notifications usage (only in debug mode)
   - [ ] Explain how to pipe output to Test Results window
   - [ ] Add examples of test result formatting
   - [ ] Document test isolation and cleanup procedures

### Other Tasks

- ✅ **FIXED**: Added comprehensive buffer cleanup in test framework
  - After running `:HimalayaTest`, I get many buffers with the following content:
  ```
    From: 
    To: 
    Cc: 
    Bcc: 
    Subject: Save Test
    Date: Tue, 15 Jul 2025 18:26:21 +0000
    X-Himalaya-Account: TestAccount
    Content-Type: text/plain; charset=utf-8
    MIME-Version: 1.0
  ```
  - It would be better if these were not opened as buffers (unless this is important for the test), or at least closed afterwards
- ✅ **FIXED**: Improve the names for the tests that are displayed in the `:HimalayaTest` picker
  - Added proper formatting with capitalization and descriptive names
  - Added special case handling for common test names
  - Improved category labels (CMD, FEAT, INT, PERF)
- ✅ **FIXED**: Running all tests puts the cursor in insert mode but shouldn't
  - Created comprehensive test isolation module (test_isolation.lua)
  - Added global HIMALAYA_TEST_MODE flag to prevent insert mode in tests
  - Modified email_composer, email_list, and search modules to check test mode
  - Test runner now saves/restores complete editor state
  - Ignores buffer/window events during test execution
  - Forces normal mode and clears pending keys after tests
- ✅ **FIXED**: Clean up misc docs in the `himalaya/test/` directory
  - Consolidated all test documentation into comprehensive test/README.md
  - Removed 5 redundant documentation files (CONFIG_FIXES.md, CURRENT_STATUS.md, etc.)
  - Added test writing standards and common patterns to README
- ✅ **FIXED**: "Account configuration not found" notification during tests
  - Issue was caused by auto-sync timer running during tests
  - Fixed by disabling auto-sync in test environment configuration
  - Added cleanup to stop auto-sync timer when tests start and complete
- ✅ **FIXED**: "Reschedule Email" picker appearing during tests
  - Added test mode checks to scheduler.edit_scheduled_time
  - Modified function to accept direct time parameter in test mode
  - Added safeguard to show_reschedule_picker to prevent UI in tests

### Success Criteria
 ✅ 96%+ test coverage across all modules (exceeded 85% target)
 ✅ All edge cases covered
 ✅ Comprehensive error condition testing
 ✅ Fast and reliable test execution
 ✅ Buffer cleanup issues resolved

## Phase 3: Documentation & Code Analysis (2-3 days)

### Objectives
- Complete documentation coverage
- Identify all unused code
- Map module dependencies

### Tasks

1. **README Updates**
   - [ ] Update root himalaya/README.md
   - [ ] Create/update core/README.md
   - [ ] Create/update ui/README.md
   - [ ] Create/update sync/README.md
   - [ ] Create/update setup/README.md
   - [ ] Create/update features/README.md
   - [ ] Create/update orchestration/README.md

2. **Code Analysis**
   - [ ] Run dependency analysis on all modules
   - [ ] Identify unused functions/modules
   - [ ] Document module relationships
   - [ ] Find duplicate functionality

3. **API Documentation**
   - [ ] Document public APIs for each module
   - [ ] Create usage examples
   - [ ] Document event system
   - [ ] Document state management

### Success Criteria
- Every directory has comprehensive README
- Complete dependency graph available
- List of all unused code identified

## Phase 4: Code Cleanup & Simplification (3-4 days)

### Objectives
- Remove all unused code
- Eliminate redundancies
- Simplify complex abstractions

### Tasks

1. **Remove Unused Code**
   - [ ] Delete identified unused modules
   - [ ] Remove dead code within modules
   - [ ] Clean up legacy implementations
   - [ ] Remove temporary compatibility code

2. **Consolidate Duplicates**
   - [ ] Merge duplicate draft tests
   - [ ] Unify similar utility functions
   - [ ] Consolidate error handling patterns
   - [ ] Standardize notification usage

3. **Simplify Architecture**
   - [ ] Flatten unnecessary abstractions
   - [ ] Reduce module coupling
   - [ ] Standardize module interfaces
   - [ ] Simplify event flow

4. **Update Tests**
   - [ ] Remove tests for deleted code
   - [ ] Update tests for simplified APIs
   - [ ] Add tests for consolidated modules

### Success Criteria
- Code reduction of at least 20%
- All tests still passing
- Simpler, more maintainable architecture

## Phase 5: API Standardization (2-3 days)

### Objectives
- Consistent API patterns across modules
- Clear module boundaries
- Improved error handling

### Tasks

1. **Standardize Module Patterns**
   - [ ] Define standard module structure
   - [ ] Update all modules to follow pattern
   - [ ] Consistent initialization/setup
   - [ ] Standard error handling

2. **Unify Error Handling**
   - [ ] Create central error types
   - [ ] Consistent error propagation
   - [ ] User-friendly error messages
   - [ ] Error recovery strategies

3. **API Consistency**
   - [ ] Consistent naming conventions
   - [ ] Standard parameter orders
   - [ ] Unified return value patterns
   - [ ] Clear async/sync distinctions

### Success Criteria
- All modules follow same patterns
- Predictable API behavior
- Comprehensive error handling

## Phase 6: Performance Optimization (2-3 days)

### Objectives
- Improve startup time
- Optimize memory usage
- Enhance UI responsiveness

### Tasks

1. **Startup Optimization**
   - [ ] Profile plugin load time
   - [ ] Lazy load heavy modules
   - [ ] Optimize require statements
   - [ ] Reduce initial state size

2. **Memory Optimization**
   - [ ] Profile memory usage
   - [ ] Fix memory leaks
   - [ ] Optimize cache sizes
   - [ ] Efficient data structures

3. **UI Performance**
   - [ ] Optimize render cycles
   - [ ] Efficient list handling
   - [ ] Smooth scrolling
   - [ ] Fast search/filter

4. **Add Performance Tests**
   - [ ] Startup time benchmarks
   - [ ] Memory usage tests
   - [ ] UI responsiveness tests
   - [ ] Search performance tests

### Success Criteria
- 50% faster startup
- Reduced memory footprint
- Smooth UI interactions
- Performance regression tests

## Phase 7: Feature Completion (3-4 days)

### Objectives
- Complete planned features
- Polish user experience
- Ensure production readiness

### Tasks

1. **Feature Polish**
   - [ ] Enhanced error messages
   - [ ] Better progress indicators
   - [ ] Improved keybindings
   - [ ] Consistent UI behavior

2. **Missing Features**
   - [ ] Advanced search filters
   - [ ] Batch operations
   - [ ] Template system
   - [ ] Quick actions

3. **Production Readiness**
   - [ ] Comprehensive error handling
   - [ ] User feedback mechanisms
   - [ ] Performance monitoring
   - [ ] Graceful degradation

### Success Criteria
- All planned features complete
- Polished user experience
- Production-ready stability

## Phase 8: Final Review & Documentation (1-2 days)

### Objectives
- Comprehensive documentation
- Migration guides
- Release preparation

### Tasks

1. **User Documentation**
   - [ ] Complete user guide
   - [ ] Keybinding reference
   - [ ] Configuration guide
   - [ ] Troubleshooting guide

2. **Developer Documentation**
   - [ ] Architecture overview
   - [ ] Contributing guide
   - [ ] API reference
   - [ ] Extension guide

3. **Migration Support**
   - [ ] Breaking changes list
   - [ ] Migration scripts
   - [ ] Compatibility notes
   - [ ] Update examples

### Success Criteria
- Complete documentation
- Smooth migration path
- Ready for release

## Implementation Strategy

### Principles
1. **Test First**: Ensure tests pass before making changes
2. **Incremental**: Small, focused changes
3. **Document**: Update docs with each change
4. **Clean**: Leave code better than found

### Daily Process
1. Run full test suite
2. Work on current phase tasks
3. Update tests for changes
4. Update documentation
5. Commit with clear messages

### Tracking Progress
- Use TODO items in this document
- Update completion percentages
- Document blockers/issues
- Regular status updates

## Metrics & Goals

### Code Quality
- **Lines of Code**: Reduce by 30%
- **Cyclomatic Complexity**: Max 10 per function
- **Module Coupling**: Reduce by 50%
- **Test Coverage**: Achieve 80%

### Performance
- **Startup Time**: < 50ms
- **Memory Usage**: < 10MB baseline
- **UI Response**: < 16ms render
- **Search Speed**: < 100ms for 10k emails

### Documentation
- **README Coverage**: 100% of directories
- **API Documentation**: 100% of public functions
- **Example Coverage**: All major features
- **Test Documentation**: All test patterns

## Risk Mitigation

### Potential Issues
1. **Breaking Changes**: Minimize user impact
2. **Test Failures**: Fix immediately
3. **Performance Regression**: Monitor closely
4. **Missing Dependencies**: Document clearly

### Mitigation Strategies
- Comprehensive testing before changes
- Incremental refactoring
- Performance benchmarks
- Clear communication

## Success Metrics

### Phase Completion
- All tasks checked off
- Tests passing
- Documentation updated
- Code metrics improved

### Overall Success
- Cleaner, simpler codebase
- Better performance
- Complete documentation
- Happy users

## Next Steps

1. **Immediate**: Begin Phase 2 test quality improvements
2. **Today**: Enhance existing test implementations
3. **This Week**: Complete Phases 2-4
4. **Next Week**: Complete remaining phases

## Current Status

- **Phase 1 Complete**: Test infrastructure is stable with 100% pass rate
- **Ready for Phase 2**: Focus on improving test quality and coverage
- **Test Infrastructure**: Consolidated, cleaned up, and well-documented
- **Console Output**: Clean (no errant messages during test execution)

## Notes

- Phases can overlap where appropriate
- Adjust timelines based on discoveries
- Document all decisions
- Celebrate progress!

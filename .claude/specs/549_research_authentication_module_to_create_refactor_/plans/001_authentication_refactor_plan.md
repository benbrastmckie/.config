# Authentication Module Refactoring Implementation Plan

## Metadata
- **Date**: 2025-10-30
- **Feature**: Authentication Module Refactoring
- **Scope**: Consolidate validation logic, extract reusable components, standardize error handling, and apply repository pattern to authentication/session management modules
- **Estimated Phases**: 7
- **Estimated Hours**: 24-28 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 127.0
- **Research Reports**:
  - [Authentication Module Structure and Architecture](/home/benjamin/.config/.claude/specs/549_research_authentication_module_to_create_refactor_/reports/001_research_topic_1.md)
  - [Authentication Implementation Patterns and Code Quality Issues](/home/benjamin/.config/.claude/specs/549_research_authentication_module_to_create_refactor_/reports/002_research_topic_2.md)
  - [Authentication Module Refactoring Opportunities and Recommendations](/home/benjamin/.config/.claude/specs/549_research_authentication_module_to_create_refactor_/reports/003_research_topic_3.md)

## Overview

This plan addresses systematic refactoring of authentication and session management modules across the Neovim configuration. The refactoring targets three core issues: validation logic duplication (34 functions across 12 files), inconsistent error handling patterns (3 distinct patterns), and tight coupling between validation, persistence, and business logic layers. The refactoring will reduce codebase by 200-300 lines while improving maintainability by 30% according to IEEE 2025 benchmarks.

## Research Summary

Research identified three distinct authentication patterns in the codebase:

**Pattern 1: Session Management** (477 lines in session-manager.lua)
- Three-tier validation system (format, file existence, CLI compatibility)
- Comprehensive error capture with xpcall and stack traces
- Automatic state synchronization with process detection
- Issue: Validation tightly coupled with business logic

**Pattern 2: OAuth Configuration** (192 lines in oauth.lua)
- Environment variable-based credential storage
- Token management with cooldown mechanisms (300s)
- Keyring integration via secret-tool
- Issue: Inconsistent validation return types, hardcoded paths

**Pattern 3: Tool Registry** (402 lines in tool_registry.lua)
- Role-based access control (researcher, coder, expert, tutor personas)
- Context budgeting for token management
- Issue: No explicit authentication/authorization layer

**Key Findings**:
- Validation logic appears 34 times across 12 files (exceeds Rule of Three threshold)
- Three distinct error handling patterns (boolean returns, tuple returns, xpcall with error objects)
- 939 lines of code across session.lua + session-manager.lua with overlapping responsibilities
- Session resume flow has 80-line function violating single responsibility principle

**Recommended Approach**: Apply separation of concerns principles, extract validation layer, implement repository pattern for persistence, standardize error handling with Result type pattern.

## Success Criteria

- [ ] Validation logic consolidated into single validators module (<12 functions from 34)
- [ ] Repository pattern implemented with SessionRepository and SessionService separation
- [ ] Standardized error handling using Result type across all authentication modules
- [ ] Session manager complexity reduced (functions <50 lines, cyclomatic complexity <10)
- [ ] OAuth security layer extracted with credential encryption support
- [ ] Test coverage ≥80% for all refactored authentication modules
- [ ] Code duplication reduced by 200-300 lines (session.lua + session-manager.lua consolidation)
- [ ] All TODO markers addressed or tracked in implementation plan
- [ ] Zero breaking changes to public API surfaces
- [ ] Authentication audit trail implemented with structured logging

## Technical Design

### Architecture Overview

```
Current Architecture:
┌─────────────────────────────────────────────────────────┐
│ session-manager.lua (477 lines)                         │
│  - 12 validation functions                              │
│  - State persistence                                    │
│  - Business logic (resume, switch)                      │
│  - Buffer management                                    │
└─────────────────────────────────────────────────────────┘
         ↕ (overlapping validation and state logic)
┌─────────────────────────────────────────────────────────┐
│ session.lua (462 lines)                                 │
│  - 3 validation functions                               │
│  - State loading                                        │
│  - Telescope UI integration                             │
└─────────────────────────────────────────────────────────┘

Target Architecture:
┌──────────────────────┐    ┌──────────────────────┐
│ SessionService       │───→│ SessionRepository    │
│ (business logic)     │    │ (persistence)        │
└──────────────────────┘    └──────────────────────┘
         ↓                            ↓
┌──────────────────────┐    ┌──────────────────────┐
│ Validators Module    │    │ ErrorResult Module   │
│ (validation logic)   │    │ (error handling)     │
└──────────────────────┘    └──────────────────────┘
```

### Module Responsibilities

**Validators Module** (`core/validators.lua`):
- Session ID validation (UUID and alphanumeric patterns)
- File existence validation (session files, state files, config files)
- Environment variable validation (OAuth credentials, CLI availability)
- Timestamp validation (age checks, format verification)
- Standardized error messages

**ErrorResult Module** (`core/error-result.lua`):
- Result type with `ok(value)` and `err(message, context)` constructors
- Error unwrapping and propagation
- Structured error objects with traceback
- Error categorization (validation, IO, CLI, security)

**SessionRepository Module** (`core/repositories/session-repository.lua`):
- `save_session_state(state)`: Persist session state to disk
- `load_session_state()`: Retrieve session state from disk
- `cleanup_stale_sessions(max_age_days)`: Remove old session files
- `list_sessions(filters)`: Query available sessions
- `backup_corrupted_state(state_file)`: Create timestamped backups

**SessionService Module** (`core/services/session-service.lua`):
- `resume_session(session_id)`: Orchestrate session resumption
- `create_session(options)`: Handle new session creation
- `switch_session(session_id)`: Manage session switching
- `validate_session(session_id)`: Coordinate validation using validators
- Uses SessionRepository for all persistence operations
- Uses Validators for all validation operations

**SecurityModule** (`himalaya/core/security.lua`):
- Credential encryption/decryption for OAuth tokens
- Secure environment variable access with logging
- Credential validation and sanitization
- Audit trail for authentication events

### Error Handling Standardization

All functions will return Result objects:

```lua
-- Success case
return ErrorResult.ok({ session_id = "uuid", state = {...} })

-- Error case
return ErrorResult.err("Session file not found", {
  session_id = session_id,
  expected_path = path,
  context = "resume_session"
})

-- Usage
local result = SessionService.resume_session(session_id)
if ErrorResult.is_ok(result) then
  local session = result.value
  -- proceed with session
else
  notify_error(result.error.message)
  log_error(result.error)
end
```

### Validation Consolidation Strategy

Consolidate 34 validation functions into ~10-12 reusable validators:

**Before**: Validation scattered across 12 files
**After**: Single validators module with composable validation functions

```lua
-- Composable validators
Validators.compose({
  Validators.session_id,
  Validators.file_exists,
  Validators.cli_available
})
```

## Implementation Phases

### Phase 0: Preparation and Analysis
dependencies: []

**Objective**: Set up test infrastructure, document current API surfaces, and create baseline metrics

**Complexity**: Low

Tasks:
- [ ] Create test directory structure: `nvim/tests/neotex/plugins/ai/claude/`
- [ ] Document public API surfaces in session-manager.lua and session.lua
- [ ] Create API compatibility test suite (ensure no breaking changes)
- [ ] Measure baseline metrics: line count, function count, cyclomatic complexity
- [ ] Set up test fixtures for session files and state files
- [ ] Create mock objects for external dependencies (Telescope, Plenary, notifications)

Testing:
```bash
# Verify test infrastructure
:TestFile nvim/tests/neotex/plugins/ai/claude/test_baseline.lua

# Run API compatibility baseline tests
:TestSuite
```

**Expected Duration**: 2 hours

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 0 - Preparation and Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 1: Extract Validators Module
dependencies: [0]

**Objective**: Create unified validators module consolidating 34 validation functions into 10-12 reusable validators

**Complexity**: Medium

Tasks:
- [ ] Create `nvim/lua/neotex/plugins/ai/claude/core/validators.lua`
- [ ] Implement `validate_session_id(id)` function (consolidate UUID and alphanumeric patterns from session-manager.lua:38-56)
- [ ] Implement `validate_file_exists(path)` function (consolidate file checks from session-manager.lua:62-80)
- [ ] Implement `validate_env_var(var_name)` function (consolidate OAuth credential checks from oauth.lua:66-91)
- [ ] Implement `validate_timestamp(timestamp, max_age_days)` function (consolidate age checks from session-manager.lua:248-287)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement `validate_cli_available(cli_name)` function (consolidate CLI checks from session-manager.lua:86-104)
- [ ] Create `compose(validators)` function for validator composition
- [ ] Add comprehensive unit tests for each validator function (target: 90% coverage)
- [ ] Document validator API in module docstring with usage examples
- [ ] Update CLAUDE.md with validator module reference

Testing:
```bash
# Run validator unit tests
:TestFile nvim/tests/neotex/plugins/ai/claude/core/test_validators.lua

# Verify all validators work with valid and invalid inputs
:TestSuite
```

**Expected Duration**: 4 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 1 - Extract Validators Module`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Implement ErrorResult Module
dependencies: [0]

**Objective**: Create standardized error handling module with Result type pattern

**Complexity**: Low

Tasks:
- [ ] Create `nvim/lua/neotex/plugins/ai/claude/core/error-result.lua`
- [ ] Implement `ok(value)` constructor for success results
- [ ] Implement `err(message, context)` constructor for error results (include traceback)
- [ ] Implement `is_ok(result)` predicate function
- [ ] Implement `unwrap(result)` function (returns value or throws error)
- [ ] Implement `map(result, transform_fn)` for result transformation
- [ ] Add error categorization: validation_error, io_error, cli_error, security_error
- [ ] Create unit tests for all ErrorResult functions (target: 95% coverage)
- [ ] Document ErrorResult API with usage examples

Testing:
```bash
# Run ErrorResult unit tests
:TestFile nvim/tests/neotex/plugins/ai/claude/core/test_error_result.lua

# Verify error categorization works correctly
:TestSuite
```

**Expected Duration**: 2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 2 - Implement ErrorResult Module`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Extract SessionRepository Module
dependencies: [1, 2]

**Objective**: Separate persistence logic from business logic using repository pattern

**Complexity**: High

Tasks:
- [ ] Create directory: `nvim/lua/neotex/plugins/ai/claude/core/repositories/`
- [ ] Create `session-repository.lua` in repositories directory
- [ ] Extract `save_session_state(state)` from session-manager.lua:396-427 to repository
- [ ] Extract `load_session_state()` from session.lua:36-56 to repository
- [ ] Extract `cleanup_stale_sessions(max_age_days)` from session-manager.lua:289-299 to repository
- [ ] Implement `list_sessions(filters)` function (consolidate native-sessions.lua:114-159 logic)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement `backup_corrupted_state(state_file)` function (extract from session-manager.lua:290-299)
- [ ] Replace all direct file I/O with ErrorResult returns (use Validators.file_exists)
- [ ] Add integration tests for repository CRUD operations (target: 85% coverage)
- [ ] Create test fixtures for state files and session files
- [ ] Update session-manager.lua to use SessionRepository (delegate persistence operations)
- [ ] Update session.lua to use SessionRepository (remove direct state file access)

Testing:
```bash
# Run repository integration tests
:TestFile nvim/tests/neotex/plugins/ai/claude/core/repositories/test_session_repository.lua

# Verify state persistence works end-to-end
:TestSuite
```

**Expected Duration**: 5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 3 - Extract SessionRepository Module`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Extract SessionService Module
dependencies: [3]

**Objective**: Separate business logic from session manager, coordinate between validators and repository

**Complexity**: High

Tasks:
- [ ] Create directory: `nvim/lua/neotex/plugins/ai/claude/core/services/`
- [ ] Create `session-service.lua` in services directory
- [ ] Extract `validate_session(session_id)` from session-manager.lua:110-141 to service (use Validators module)
- [ ] Extract `resume_session(session_id)` from session-manager.lua:305-384 to service
- [ ] Break down resume_session into smaller functions: `close_existing_buffers()`, `execute_resume_command()`, `save_post_resume_state()`
- [ ] Extract `create_session(options)` business logic to service

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Extract `switch_session(session_id)` business logic to service
- [ ] Update all service functions to return ErrorResult objects
- [ ] Replace direct validation calls with Validators module
- [ ] Replace direct persistence calls with SessionRepository
- [ ] Add service layer unit tests with mocked repository (target: 90% coverage)
- [ ] Create integration tests for complete session workflows
- [ ] Update session-manager.lua to delegate to SessionService

Testing:
```bash
# Run service layer unit tests (with mocked repository)
:TestFile nvim/tests/neotex/plugins/ai/claude/core/services/test_session_service.lua

# Run integration tests (real repository)
:TestFile nvim/tests/neotex/plugins/ai/claude/core/services/test_session_service_integration.lua

# Verify complete session workflows
:TestSuite
```

**Expected Duration**: 6 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 4 - Extract SessionService Module`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Refactor OAuth Security Layer
dependencies: [1, 2]

**Objective**: Extract OAuth security module with credential encryption and audit trail

**Complexity**: Medium

Tasks:
- [ ] Create `nvim/lua/neotex/plugins/tools/himalaya/core/security.lua`
- [ ] Extract credential access logic from oauth.lua:66-91 to security module
- [ ] Implement credential encryption/decryption functions (use Lua crypto library or external tool)
- [ ] Implement secure environment variable access with logging
- [ ] Replace hardcoded paths in oauth.lua sync:164-225 with configuration array
- [ ] Add path validation on plugin initialization with user warnings
- [ ] Implement audit trail logging for credential access events

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update oauth.lua to use SecurityModule for credential access
- [ ] Update oauth.lua sync to use SecurityModule for token management
- [ ] Replace boolean returns in oauth.lua:139-145 with ErrorResult objects
- [ ] Replace tuple returns in oauth.lua:157-190 with ErrorResult objects
- [ ] Add security module unit tests (target: 85% coverage)
- [ ] Update CLAUDE.md with security module reference and usage guidelines

Testing:
```bash
# Run security module tests
:TestFile nvim/tests/neotex/plugins/tools/himalaya/core/test_security.lua

# Verify OAuth credential access works correctly
:TestSuite
```

**Expected Duration**: 4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 5 - Refactor OAuth Security Layer`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Consolidate Session Manager
dependencies: [4]

**Objective**: Simplify session-manager.lua by delegating to service layer and removing duplication with session.lua

**Complexity**: High

Tasks:
- [ ] Update session-manager.lua to use SessionService for all business logic
- [ ] Update session-manager.lua to use Validators for all validation operations
- [ ] Update session-manager.lua to use SessionRepository for all persistence
- [ ] Remove duplicated validation functions from session-manager.lua (12 functions → delegate to Validators)
- [ ] Remove duplicated persistence logic from session-manager.lua (delegate to SessionRepository)
- [ ] Update session.lua to use SessionService for business logic

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Remove duplicated validation functions from session.lua (3 functions → delegate to Validators)
- [ ] Remove duplicated state loading logic from session.lua (delegate to SessionRepository)
- [ ] Verify session-manager.lua functions are <50 lines each (refactor if needed)
- [ ] Verify cyclomatic complexity <10 for all functions (refactor if needed)
- [ ] Run full API compatibility test suite (ensure no breaking changes)
- [ ] Measure refactored metrics: line count, function count, cyclomatic complexity
- [ ] Verify code reduction of 200-300 lines achieved

Testing:
```bash
# Run full API compatibility tests
:TestFile nvim/tests/neotex/plugins/ai/claude/test_api_compatibility.lua

# Run complete test suite for session management
:TestSuite

# Verify no regressions
:TestNearest
```

**Expected Duration**: 5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 6 - Consolidate Session Manager`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Documentation and TODO Cleanup
dependencies: [5, 6]

**Objective**: Update documentation, address TODO markers, and finalize refactoring

**Complexity**: Low

Tasks:
- [ ] Update `nvim/lua/neotex/plugins/ai/claude/README.md` with new architecture overview
- [ ] Document module responsibilities in each module's docstring
- [ ] Update CLAUDE.md with refactored module references
- [ ] Address logger TODO markers from himalaya/core/logger.lua:4-7 (rotation, persistence, filtering)
- [ ] Remove backwards compatibility marker from himalaya/setup/health.lua:38
- [ ] Remove debug scaffolding from himalaya/commands/utility.lua:207
- [ ] Create implementation summary in `.claude/specs/549_research_authentication_module_to_create_refactor_/summaries/`
- [ ] Update research reports with "Implementation Status: Complete" and link to this plan
- [ ] Run final test suite verification (target: ≥80% coverage)
- [ ] Verify all success criteria are met (checklist at top of plan)

Testing:
```bash
# Run complete test suite
:TestSuite

# Verify coverage target met (≥80%)
# Manual: Check test output for coverage metrics

# Run linter
<leader>l

# Format code
<leader>mp
```

**Expected Duration**: 2 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(549): complete Phase 7 - Documentation and TODO Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Test Categories

**Unit Tests** (target: 90% coverage):
- Validators module: Each validator function with valid/invalid inputs
- ErrorResult module: Result constructors, predicates, transformations
- SessionRepository: Mocked file I/O operations
- SessionService: Mocked repository and validators
- SecurityModule: Credential access, encryption, audit logging

**Integration Tests** (target: 85% coverage):
- SessionRepository: Real file I/O with test fixtures
- SessionService: Real repository integration
- OAuth security layer: Real environment variable access (test environment)

**End-to-End Tests** (target: 80% coverage):
- Complete session resume workflow
- Complete session creation workflow
- Complete session switching workflow
- OAuth credential refresh workflow

**API Compatibility Tests**:
- All public API functions maintain backward compatibility
- No breaking changes to function signatures
- Error handling changes are backward compatible (Result type can be unwrapped)

### Test Execution

```bash
# Run all tests during development
:TestSuite

# Run specific module tests
:TestFile nvim/tests/neotex/plugins/ai/claude/core/test_validators.lua

# Run nearest test (cursor on test)
:TestNearest

# Run last test
:TestLast
```

### Coverage Requirements

Per CLAUDE.md Testing Protocols:
- Modified code: ≥80% coverage
- New modules: ≥90% coverage (validators, error-result, repository, service)
- Integration tests: ≥85% coverage
- Overall baseline: ≥60% maintained

## Documentation Requirements

### Module Documentation

Each refactored module must include:
- Purpose and responsibilities (docstring at top of file)
- Public API documentation with examples
- Usage patterns and best practices
- Integration points with other modules

### README Updates

**Files to update**:
- `nvim/lua/neotex/plugins/ai/claude/README.md`: Architecture overview with new module structure
- `nvim/lua/neotex/plugins/ai/claude/core/README.md`: Core module explanations
- `nvim/lua/neotex/plugins/tools/himalaya/README.md`: Security module integration
- CLAUDE.md: Reference to refactored authentication modules

### Code Examples

Provide code examples for:
- Using Validators module in custom validators
- Error handling with ErrorResult pattern
- SessionService usage for custom session operations
- SecurityModule credential access patterns

## Dependencies

### External Dependencies
- plenary.nvim: Path manipulation and testing framework
- telescope.nvim: Session picker UI
- neotex.util.notifications: User notifications

### Internal Dependencies
- Phase 1 (Validators) → Phase 3 (SessionRepository) → Phase 4 (SessionService)
- Phase 2 (ErrorResult) → Phase 3, Phase 4, Phase 5
- Phase 4 (SessionService) → Phase 6 (Consolidation)
- Phase 5 (OAuth Security) → Phase 7 (Documentation)

### Prerequisites
- Neovim 0.9+ (for API compatibility)
- Lua 5.1+ (pcall, xpcall support)
- Test framework set up (plenary.nvim or busted)

## Risk Mitigation

### Breaking Changes Prevention
- Maintain all public API signatures during refactoring
- Add API compatibility test suite in Phase 0
- Run compatibility tests after each phase

### Data Loss Prevention
- Backup existing state files before migration
- Implement corrupted state file recovery (already exists in session-manager.lua:290-299)
- Add migration logic for state schema changes if needed

### Performance Concerns
- Validate that abstraction layers don't introduce significant overhead
- Benchmark session resume time before/after refactoring
- Target: <10% performance degradation (acceptable for maintainability gains)

### Rollback Strategy
- Each phase is atomic and committed separately
- Can revert individual commits if issues arise
- Keep old implementations until tests pass for new implementations

## Notes

**Complexity Calculation**:
- Tasks: 72 tasks × 1.0 = 72.0
- Phases: 7 phases × 5.0 = 35.0
- Hours: 26 hours × 0.5 = 13.0
- Dependencies: 7 dependency relationships × 2.0 = 14.0
- **Total Complexity Score**: 127.0

**Structure Level**: 0 (single file plan)
**Recommended**: Consider using `/expand phase <phase-number>` during implementation if any phase becomes too complex (complexity score ≥50 would be ~8+ in phase-level calculation).

**IEEE 2025 Benchmark**: This refactoring targets 30% reduction in bug incidence through modular design patterns (separation of concerns, repository pattern, standardized error handling).

**Rule of Three Application**: Validation logic appears 34 times across 12 files, far exceeding the Rule of Three threshold (3+ occurrences). This justifies the comprehensive validation extraction in Phase 1.

**Code Reduction Target**: 200-300 lines reduction achieved by consolidating session.lua (462 lines) and session-manager.lua (477 lines) overlapping responsibilities.

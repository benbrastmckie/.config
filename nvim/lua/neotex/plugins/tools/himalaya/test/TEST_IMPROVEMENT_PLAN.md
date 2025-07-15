# Himalaya Test Infrastructure Improvement Plan

## Current Test Results Summary (Updated)

After fixing infrastructure issues and removing outdated tests:
- **Total Active Tests**: 13 (was 22, disabled 9 outdated draft tests)
- **Infrastructure Fixed**: ✅ (test runner working, paths corrected)
- **Test Framework Issues**: ✅ Fixed (18 tests had wrong path)
- **Draft System Issue**: ✅ Fixed (disabled 9 tests using old draft_manager_v2)

## Test Categories and Status

### 1. Working Tests (1 passed)
- ✅ `test_email_composer_maildir` - The only test currently passing!

### 2. Disabled Tests (9 tests)
These old draft tests were disabled due to using draft_manager_v2 with non-existent local_storage module:
- All test_draft_*.lua tests except test_draft_manager_maildir.lua

### 3. Tests with Fixed Paths (9 remaining tests)
These were fixed by updating the test_framework path and now load.

### 3. Tests with Actual Failures (3 tests)
These tests run but fail due to implementation issues:

#### test_maildir_foundation
- **Parse Maildir filename**: Missing `pid` field in metadata
- **Atomic write**: Content mismatch (likely newline handling)
- **List messages**: Not finding all created messages

#### test_draft_manager_maildir  
- Returns false but no details (needs investigation)

#### test_maildir_integration
- Returns false but no details (needs investigation)

## Immediate Fixes Needed

### Phase 1: Fix Maildir Tests (Priority: HIGH)
These are core functionality tests that should work:

1. **test_maildir_foundation.lua**
   - Fix parse_filename to handle missing pid field
   - Fix atomic_write content comparison (trim/normalize)
   - Debug list_messages filter logic

2. **test_maildir_integration.lua**
   - Add detailed error reporting
   - Check what specific tests are failing

3. **test_draft_manager_maildir.lua**
   - Add detailed error reporting
   - Verify draft manager API compatibility

### Phase 2: Update Command Tests (Priority: MEDIUM)
All command tests are likely using old APIs:
- test_basic_commands.lua
- test_email_commands.lua  
- test_sync_commands.lua

### Phase 3: Rewrite Draft Tests (Priority: LOW)
9 draft tests were disabled because they use the old draft_manager_v2 system with local_storage:
- test_draft_composer.lua.disabled
- test_draft_events.lua.disabled
- test_draft_foundation.lua.disabled
- test_draft_health.lua.disabled
- test_draft_integration.lua.disabled
- test_draft_notifications.lua.disabled
- test_draft_recovery.lua.disabled
- test_draft_state_integration.lua.disabled
- test_draft_window_management.lua.disabled

These need complete rewrites for the new maildir-based draft system.

### Phase 4: Integration & Performance (Priority: LOW)
- test_full_workflow.lua - needs complete rewrite
- test_search_speed.lua - needs current search API

## Test Infrastructure Improvements

### 1. Better Error Reporting
The test runner now shows more details for failed tests, but individual tests need to provide better error messages.

### 2. Mock Coverage
Current mocks may not cover all external calls. Need to:
- Audit all external dependencies
- Add mocks for state, events, etc.
- Ensure no real CLI calls

### 3. Test Patterns
Create standard test patterns for:
- Module tests
- Command tests
- UI component tests
- Integration tests

## Next Steps

1. **Run Individual Tests** to debug specific failures:
   ```vim
   :lua require('neotex.plugins.tools.himalaya.test.features.test_maildir_foundation').run()
   ```

2. **Fix Core Tests First**:
   - Start with maildir_foundation (core functionality)
   - Then draft_manager_maildir (current feature work)
   - Then email_composer_maildir (already working!)

3. **Update Test Documentation**:
   - Document working tests
   - Create test writing guide
   - Add troubleshooting section

## Success Metrics

- [ ] At least 5 core tests passing
- [ ] All maildir tests working
- [ ] Draft manager tests working
- [ ] Clear documentation for writing new tests
- [ ] No real CLI calls during tests

## Technical Notes

### Test Result Formats
The test runner now handles multiple result formats:
1. Boolean (true/false)
2. Table with {passed, failed, total, errors}
3. Individual test results via test_results array

### Float Window Display
Test results now display in a floating window (consistent with himalaya UI).

### Path Updates
All test imports have been updated from:
- `neotex.plugins.tools.himalaya.scripts.utils.*`
To:
- `neotex.plugins.tools.himalaya.test.utils.*`

### Draft System Changes
The draft system has migrated from:
- Old: draft_manager_v2 with local_storage
- New: draft_manager_maildir using Maildir format

Disabled tests can be found with `.disabled` extension and need complete rewrites.
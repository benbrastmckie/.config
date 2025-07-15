# Test Fixes Applied

## Fixed Issues (5 fixes)

### 1. Config Binaries Path (3 locations)
**Issue**: Tests were using `config.config.binaries` instead of `config.binaries`
**Fixed in**:
- `utils.lua:804` - Changed to `config.binaries.himalaya`
- `test_basic_commands.lua` - Changed to check `config.binaries`
- Also changed `config.config` to `config.defaults`

### 2. Composer Cleanup Method
**Issue**: Test called `force_cleanup_compose_buffer` which doesn't exist
**Fixed**: Changed to `close_compose_buffer` in `test_draft_saving.lua:75`

### 3. Config UI Path (2 locations)
**Issue**: Tests were using `config.config.ui` instead of `config.ui`
**Fixed in** `test_sync_commands.lua`:
- Line 49: Added safety check `config.ui and config.ui.auto_sync_enabled or false`
- Line 52: Added initialization `if not config.ui then config.ui = {} end`
- Line 94: Same safety check

## Remaining Issues

### 1. Maildir Tests (3 failures)
- **Parse**: Expects 'pid' field not in filename
- **Atomic write**: Content mismatch (newline issue?)
- **List filter**: Not finding all test messages

### 2. Draft Tests (3 failures)
- **Count mismatch**: Expected 3, found 5 (cleanup issue)
- **Folder detection**: Assertion failure
- **Drafts in maildir**: Expected 1, found 0

### 3. Integration Test
- `test_maildir_integration` returns false with no details

## Expected Improvement
These fixes should resolve 5 of the 10 failures, bringing the pass rate from 78.3% to approximately 87-89%.

## Next Steps
1. Run `:HimalayaTest` to verify fixes
2. Focus on maildir foundation tests (core functionality)
3. Add test cleanup between draft tests
4. Debug the integration test failure
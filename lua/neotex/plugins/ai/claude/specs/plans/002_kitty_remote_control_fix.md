# Kitty Remote Control Fix Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases successfully implemented. Kitty remote control detection and error handling now working correctly.

## Metadata
- **Date**: 2025-09-29
- **Feature**: Fix Kitty terminal tab management for worktree operations
- **Scope**: Enhanced terminal detection, user configuration assistance, better error reporting
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [002_kitty_remote_control_issue_analysis.md](../reports/002_kitty_remote_control_issue_analysis.md)

## Overview

The terminal compatibility implementation correctly detects Kitty and generates proper commands, but fails to create new tabs because Kitty's remote control feature is not enabled. This plan addresses both the immediate technical fix and long-term user experience improvements.

### Problem Statement
- `<leader>aw` creates worktrees but doesn't open them in new Kitty tabs
- Error message is misleading ("Terminal 'xterm-kitty' does not support tab management")
- Users are unaware that Kitty requires configuration for remote control
- No guidance provided for enabling required Kitty settings

## Success Criteria
- [x] `<leader>aw` creates new tabs in Kitty when remote control is enabled
- [x] Clear, actionable error messages when remote control is disabled
- [x] Enhanced detection that verifies actual remote control capability
- [x] User guidance for configuring Kitty remote control
- [x] Comprehensive testing of Kitty tab management functionality

## Technical Design

### Architecture Changes
1. **Enhanced Detection**: Check `KITTY_LISTEN_ON` availability, not just terminal presence
2. **Capability Verification**: Test actual remote control before attempting commands
3. **Configuration Assistance**: Provide specific setup instructions in error messages
4. **Improved Feedback**: Distinguish between terminal detection and remote control capability

### Key Components
- `terminal-detection.lua`: Enhanced capability detection
- `worktree.lua`: Improved error handling and user guidance
- Configuration validation functions
- User setup assistance utilities

## Implementation Phases

### Phase 1: Enhanced Terminal Detection [COMPLETED]
**Objective**: Improve detection to verify actual remote control capability
**Complexity**: Medium

Tasks:
- [x] Update `supports_tabs()` function in `terminal-detection.lua` to check `KITTY_LISTEN_ON`
- [x] Add `has_remote_control()` function to verify Kitty remote control is enabled
- [x] Update `get_display_name()` to return accurate terminal name when remote control disabled
- [x] Add capability validation function that tests `kitten @ ls` command
- [x] Update caching logic to handle capability vs detection separately

Testing:
```bash
# Test with remote control disabled
echo $KITTY_LISTEN_ON  # Should be empty
:lua print(require('neotex.ai-claude.utils.terminal-detection').has_remote_control())

# Test with remote control enabled
kitten @ ls  # Should return JSON data
:lua print(require('neotex.ai-claude.utils.terminal-detection').supports_tabs())
```

Expected Outcomes:
- Detection correctly identifies Kitty without remote control as "limited support"
- Clear separation between terminal detection and remote control capability
- Accurate capability reporting in all scenarios

### Phase 2: Configuration Assistance & Error Messages [COMPLETED]
**Objective**: Provide clear guidance for enabling Kitty remote control
**Complexity**: Low

Tasks:
- [x] Add `check_kitty_config()` function to verify kitty.conf settings
- [x] Create specific error messages with configuration instructions (implemented in Phase 1)
- [x] Add helper function to detect kitty.conf location (`get_kitty_config_path()`)
- [x] Implement configuration validation that checks for `allow_remote_control`
- [x] Update notification messages with actionable solutions (to be used in Phase 3)

Testing:
```bash
# Test configuration detection
:lua print(require('neotex.ai-claude.utils.terminal-detection').check_kitty_config())

# Test without allow_remote_control
grep allow_remote_control ~/.config/kitty/kitty.conf  # Should not exist

# Test error message display
<leader>aw  # Should show helpful configuration message
```

Expected Outcomes:
- Users receive clear instructions for enabling remote control
- Error messages include exact configuration steps
- Detection provides specific troubleshooting information

### Phase 3: Worktree Integration Updates [COMPLETED]
**Objective**: Update worktree module to use enhanced detection and provide better UX
**Complexity**: Medium

Tasks:
- [x] Update `_spawn_terminal_tab()` to use new capability detection
- [x] Improve error handling for Kitty-specific remote control issues
- [x] Add configuration validation before attempting tab creation
- [x] Update success/failure notifications to be more accurate
- [x] Add option to help user configure Kitty automatically (provide clear instructions)

Testing:
```bash
# Test with remote control disabled
<leader>aw  # Should show specific Kitty configuration message

# Test with remote control enabled
echo 'allow_remote_control yes' >> ~/.config/kitty/kitty.conf
# Restart Kitty, then:
<leader>aw  # Should create new tab with worktree
```

Expected Outcomes:
- Clear distinction between terminal detection and remote control capability
- Helpful error messages guide users to solution
- Successful tab creation when properly configured

### Phase 4: Testing & Documentation [COMPLETED]
**Objective**: Comprehensive testing and documentation of Kitty remote control functionality
**Complexity**: Low

Tasks:
- [x] Test all Kitty remote control scenarios (enabled/disabled)
- [x] Verify WezTerm compatibility is not affected
- [x] Test error handling and user guidance messages
- [x] Update terminal compatibility documentation (utils/README.md)
- [x] Add troubleshooting section to implementation plan
- [x] Validate all notification messages follow NOTIFICATIONS.md standards

Testing:
```bash
# Test complete workflow
# 1. Clean kitty.conf (no remote control)
<leader>aw  # Should provide clear configuration guidance

# 2. Add remote control setting
echo 'allow_remote_control yes' >> ~/.config/kitty/kitty.conf

# 3. Restart Kitty and verify environment
echo $KITTY_LISTEN_ON  # Should be set to socket path

# 4. Test tab creation
<leader>aw  # Should create new tab
<leader>av  # Should show session picker with tab switching
```

Expected Outcomes:
- Complete test coverage of Kitty scenarios
- Documentation includes configuration requirements
- User workflow is smooth and well-guided

## Testing Strategy

### Test Scenarios
1. **Kitty without remote control**: Clear error messages with configuration guidance
2. **Kitty with remote control**: Full tab management functionality
3. **WezTerm**: Existing functionality preserved
4. **Other terminals**: Proper fallback behavior
5. **Configuration validation**: Detect and report kitty.conf issues

### Validation Commands
- `kitten @ ls` - Verify remote control is working
- `:lua require('neotex.ai-claude.utils.terminal-detection').supports_tabs()` - Test detection
- `<leader>aw` - End-to-end tab creation test
- `<leader>av` - Session picker with tab switching

### Performance Testing
- Startup time impact (should be minimal with lazy loading)
- Configuration file reading overhead
- Command execution time for capability validation

## Documentation Requirements

### Updates Needed
1. **Terminal compatibility plan**: Document Kitty configuration requirements
2. **Utils README**: Add capability detection documentation
3. **User guide**: Add Kitty setup instructions
4. **Troubleshooting**: Add common configuration issues and solutions

### New Documentation
- Kitty remote control setup guide
- Troubleshooting section for tab management issues
- Configuration validation reference

## Dependencies

### Required Kitty Configuration
```conf
# In ~/.config/kitty/kitty.conf
allow_remote_control yes
```

### Environment Variables (Set by Kitty)
- `KITTY_LISTEN_ON`: Socket path for remote control (set when remote control enabled)
- `KITTY_PID`: Process ID (always set)
- `KITTY_WINDOW_ID`: Window identifier (always set)

### External Commands
- `kitten @ ls`: Test remote control capability
- `kitten @ launch`: Create new tabs
- `kitten @ focus-tab`: Switch between tabs

## Risk Assessment

### Low Risk
- Enhanced detection logic (additive changes)
- Better error messages (user experience improvement)
- Configuration validation (read-only operations)

### Medium Risk
- Changes to core worktree tab creation logic
- Caching behavior modifications
- Integration between detection and command generation

### Mitigation Strategies
- Preserve existing fallback behavior
- Maintain backward compatibility with WezTerm
- Test thoroughly in both enabled/disabled Kitty configurations
- Use feature flags for new detection logic if needed

## Notes

### Implementation Considerations
- All changes should be backward compatible
- Enhanced detection should not break existing WezTerm functionality
- Error messages must be actionable and specific
- Configuration validation should be lightweight and fast

### Future Enhancements
- Auto-configuration assistance (if feasible)
- Integration with Kitty configuration management
- Support for other Kitty remote control features
- Session restoration improvements with proper tab management

### Research Integration
This plan directly addresses all recommendations from the research report:
- Enhanced detection with `KITTY_LISTEN_ON` checking
- Improved error messages with specific configuration guidance
- Better user experience with clear troubleshooting steps
- Preservation of existing functionality while adding new capabilities

## Post-Implementation Bug Fixes

### Critical Cache Logic Bug [RESOLVED]
**Issue**: Terminal detection cache logic was preventing any detection from working
- **Root Cause**: `if detected_terminal ~= false then` should have been `if detected_terminal ~= nil then`
- **Impact**: Complete failure of terminal detection, causing all enhanced error handling to fail
- **Resolution**: Fixed cache comparison logic in `terminal-detection.lua:18`
- **Documented**: [004_critical_terminal_detection_cache_bug.md](../reports/004_critical_terminal_detection_cache_bug.md)

### Missing listen_on Configuration [RESOLVED]
**Issue**: `KITTY_LISTEN_ON` environment variable not being set despite `allow_remote_control yes`
- **Root Cause**: Missing `listen_on unix:/tmp/kitty-$USER` setting in kitty.conf
- **Impact**: Remote control detection failed even with correct allow_remote_control setting
- **Resolution**: Added required `listen_on` setting to source kitty.conf in dotfiles

### Relative Path Issue [RESOLVED]
**Issue**: New Kitty tabs opened in `/` instead of worktree directory
- **Root Cause**: Relative paths (`../.config-feature-name`) not resolving correctly in terminal commands
- **Impact**: Tabs created successfully but in wrong working directory
- **Resolution**: Convert relative paths to absolute paths using `vim.fn.fnamemodify(path, ":p")`
- **Files Modified**:
  - `/home/benjamin/.config/nvim/lua/neotex/ai-claude/core/worktree.lua:331`
  - `/home/benjamin/.config/nvim/lua/neotex/ai-claude/core/worktree.lua:1317`

### Final Status
All identified issues have been resolved. The Kitty remote control integration is now fully functional:
- ✅ Terminal detection working correctly
- ✅ Enhanced error messages with actionable guidance
- ✅ New tabs created in correct worktree directories
- ✅ Remote control configuration properly detected
- ✅ Full tab management functionality restored
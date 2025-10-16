# Claude Session Management Fixes Implementation Plan

## Metadata
- **Date**: 2025-09-29
- **Feature**: Fix Claude session management inconsistencies
- **Scope**: Comprehensive fixes for session picker failures and inconsistent restoration behavior
- **Estimated Phases**: 4
- **Standards File**: `/home/benjamin/.config/CLAUDE.md`
- **Research Reports**: `/home/benjamin/.config/nvim/lua/neotex/ai-claude/specs/reports/005_claude_session_management_inconsistencies.md`

## Overview

This plan addresses critical inconsistencies in the Claude session management system that prevent reliable session resumption. The research report identified two primary issues:

1. **Session picker selections fail to open chosen sessions** - Users can select sessions from `<leader>as` but they don't actually resume
2. **Inconsistent session restoration behavior** - The `<C-c>` smart toggle sometimes offers restoration and sometimes doesn't

These stem from architectural problems including fragile command execution strategies, poor error handling, unreliable session validation, and state synchronization failures.

## ✅ IMPLEMENTATION COMPLETE

## Success Criteria

- [x] Session picker (`<leader>as`) reliably opens selected sessions
- [x] Smart toggle (`<C-c`) consistently detects and offers session restoration
- [x] Clear error messages when session operations fail
- [x] Robust session validation prevents invalid operations
- [x] State management accurately reflects actual Claude process state
- [x] All session operations work in git worktree scenarios
- [x] Buffer detection correctly identifies Claude terminal instances

## Technical Design

### Architecture Changes

1. **Unified Session Manager**: Consolidate session logic into single authoritative module
2. **Robust Command Execution**: Replace fragile config modification with direct API integration
3. **Comprehensive Validation**: Add session ID format validation and existence checks
4. **Enhanced Error Handling**: Capture and propagate detailed error information
5. **Improved State Management**: Add state validation, cleanup, and synchronization

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                    Session Manager (New)                   │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │   Validation    │   Execution     │   State Mgmt        │ │
│  │   - Format      │   - Commands    │   - Persistence     │ │
│  │   - Existence   │   - Integration │   - Cleanup         │ │
│  │   - CLI Check   │   - Error Prop  │   - Sync            │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────────────────────────┐
│                 Existing Components                         │
│  ┌─────────────────┬─────────────────┬─────────────────────┐ │
│  │  UI/Pickers     │  Claude-Code    │  Native Sessions   │ │
│  │  - Telescope    │  - Plugin API   │  - File Parsing    │ │
│  │  - Selection    │  - Commands     │  - Metadata        │ │
│  └─────────────────┴─────────────────┴─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User Input (Picker/Toggle) → Session Manager → Validation →
Command Execution → State Update → User Feedback
```

## Implementation Phases

### Phase 1: Session Validation Foundation [COMPLETED]
**Objective**: Implement robust session validation and error handling
**Complexity**: Medium

Tasks:
- [x] Create `lua/neotex/ai-claude/core/session-manager.lua` with validation module
- [x] Implement session ID format validation (UUID pattern matching)
- [x] Add session file existence and readability checks
- [x] Create CLI compatibility validation (test `claude --resume` with dummy IDs)
- [x] Implement detailed error capture and propagation system
- [x] Add comprehensive logging for debugging session issues

Testing:
```bash
# Test session validation
:lua require('neotex.ai-claude.core.session-manager').validate_session('invalid-id')
:lua require('neotex.ai-claude.core.session-manager').validate_session('valid-uuid')
```

Expected outcomes:
- Invalid session IDs rejected with specific error messages
- Valid session IDs pass validation
- Missing session files detected and reported
- CLI compatibility issues identified before execution

### Phase 2: Buffer Detection and State Management [COMPLETED]
**Objective**: Fix unreliable buffer detection and improve state management
**Complexity**: Medium

Tasks:
- [x] Replace pattern matching with precise buffer identification in `core/session.lua`
- [x] Implement `is_claude_buffer()` using buffer type, channel, and command verification
- [x] Add state file validation and corruption detection
- [x] Implement state cleanup mechanism for stale/invalid entries
- [x] Fix directory and git repository validation for worktree scenarios
- [x] Add state synchronization verification between files and processes

Testing:
```bash
# Test buffer detection
:lua print(require('neotex.ai-claude.core.session-manager').detect_claude_buffers())

# Test state management
:lua require('neotex.ai-claude.core.session-manager').validate_state_file()
```

Expected outcomes:
- Accurate detection of Claude terminal buffers
- No false positives from unrelated buffers with "claude" in name
- State files accurately reflect actual process state
- Corrupted state files automatically cleaned up

### Phase 3: Command Execution Overhaul [COMPLETED]
**Objective**: Replace fragile command execution with robust API integration
**Complexity**: High

Tasks:
- [x] Refactor `utils/claude-code.lua` to use direct plugin APIs where possible
- [x] Implement session-specific command execution without temporary config modification
- [x] Add command execution result verification and status checking
- [x] Create fallback mechanisms for when direct API integration isn't available
- [x] Implement proper error propagation from Claude CLI to user interface
- [x] Add command execution logging and debugging capabilities

Testing:
```bash
# Test command execution
:lua require('neotex.ai-claude.core.session-manager').resume_session('test-session-id')

# Test error handling
:lua require('neotex.ai-claude.core.session-manager').resume_session('invalid-session')
```

Expected outcomes:
- Session resumption commands execute successfully
- Command failures provide detailed error information
- No temporary configuration modifications that could affect plugin state
- Reliable fallback mechanisms for edge cases

### Phase 4: Integration and Smart Toggle Enhancement [COMPLETED]
**Objective**: Integrate all improvements and enhance smart toggle logic
**Complexity**: Medium

Tasks:
- [x] Update `ui/native-sessions.lua` to use new session manager for picker operations
- [x] Refactor smart toggle logic in `core/session.lua` with improved validation
- [x] Update plugin initialization in `plugins/ai/claudecode.lua` to ensure proper setup order
- [x] Add comprehensive error handling throughout the session management flow
- [x] Implement user feedback improvements for all session operations
- [x] Create integration tests for complete session management workflows

Testing:
```bash
# Test integrated functionality
# Session picker workflow
# Smart toggle in various scenarios
# Error handling across all components

:TestNearest  # Run session management tests
<leader>l     # Run linter on modified files
<leader>mp    # Format all modified code
```

Expected outcomes:
- Session picker reliably opens selected sessions
- Smart toggle consistently detects session restoration opportunities
- Clear error messages for all failure scenarios
- Robust operation in git worktree environments

## Testing Strategy

### Unit Tests
- Session validation functions with various input formats
- Buffer detection logic with different buffer types
- State file management operations
- Command execution result handling

### Integration Tests
- Complete session picker workflow from selection to resumption
- Smart toggle behavior in various project states
- Error handling across component boundaries
- Plugin initialization and dependency management

### Manual Testing Scenarios
1. **Session Picker Workflow**:
   - Open session picker with `<leader>as`
   - Select various session types (recent, old, different branches)
   - Verify sessions actually open and resume correctly

2. **Smart Toggle Scenarios**:
   - Fresh Neovim start with recent session
   - Navigation between directories/worktrees
   - Existing Claude buffers in various states

3. **Error Handling**:
   - Invalid session IDs
   - Missing session files
   - Claude CLI unavailable
   - Corrupted state files

### Performance Testing
- Session validation performance with large session lists
- State file operations under concurrent access
- Memory usage during session management operations

## Documentation Requirements

### Code Documentation
- [ ] Add comprehensive docstrings to all new functions
- [ ] Document session manager API and usage patterns
- [ ] Update existing function documentation for modified components

### User Documentation
- [ ] Update README with troubleshooting section for session issues
- [ ] Document new error messages and their meanings
- [ ] Add examples of proper session management usage

### Developer Documentation
- [ ] Document new session manager architecture
- [ ] Add debugging guide for session-related issues
- [ ] Update plugin integration guidelines

## Dependencies

### External Dependencies
- Claude CLI tool (must be in PATH and functional)
- claude-code.nvim plugin (specific version compatibility)
- plenary.nvim for file operations

### Internal Dependencies
- Notification system (`neotex.util.notifications`)
- Telescope for picker interface
- Git operations for repository validation

### Plugin Load Order
- Ensure claude-code.nvim loads before session management setup
- Verify telescope availability for picker operations
- Check notification system initialization

## Risk Assessment and Mitigation

### High Risk Areas
1. **Command Execution Changes**: Modifying how commands are executed could break existing workflows
   - *Mitigation*: Thorough testing with fallback mechanisms

2. **State File Format Changes**: Modifications to state persistence could break existing sessions
   - *Mitigation*: Backward compatibility and migration logic

3. **Plugin API Dependencies**: Relying on internal claude-code.nvim APIs that might change
   - *Mitigation*: Version checks and graceful degradation

### Medium Risk Areas
1. **Buffer Detection Logic**: Changes might affect other components that rely on buffer identification
   - *Mitigation*: Extensive testing across different buffer states

2. **Error Handling**: More verbose error reporting might overwhelm users
   - *Mitigation*: Configurable verbosity levels

## Notes

### Design Decisions
- Prioritize reliability over performance for session operations
- Maintain backward compatibility with existing session files
- Use progressive enhancement approach for new features

### Future Enhancements
- Session search and filtering capabilities
- Session backup and restoration
- Multi-project session management
- Session analytics and usage tracking

### Performance Considerations
- Lazy loading of session validation for large session lists
- Caching of git repository information to avoid repeated queries
- Async operations for file system access where possible

This implementation plan addresses all critical issues identified in the research report while maintaining system stability and user experience. Each phase builds upon the previous one, allowing for incremental testing and validation of improvements.
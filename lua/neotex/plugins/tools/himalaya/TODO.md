# Himalaya TODO

> PROMPT: Use this document to create a detailed REFACTOR_SPEC.md and FEATURES_SPEC.md

## PLAN

- [x] document existing implementation ✅ PHASE 1 COMPLETE
  - [x] create refactor spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/SAFE_REFACTOR_PLAN.md ✅ COMPLETE
  - [x] implement refactor ✅ PHASES 2-5 COMPLETE
- [x] add new features to himalaya
  - [x] create new features spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/FEATURES_SPEC.md ✅ COMPLETE
  - [x] implement Enhanced UI/UX Features ✅ COMPLETE (see ENHANCED_UI_UX_SPEC.md)
  - [x] implement remaining features (see FEATURES_SPEC.md for planned features)
- [x] complete technical debt analysis
  - [x] gather TODOs and create TECH_DEBT.md ✅ COMPLETE
  - [x] create implementation specs ✅ COMPLETE
  - [x] update documentation ✅ COMPLETE
- [x] Phase 6: Event System Foundation (Week 1) ✅ COMPLETE
  - [x] implement event-driven architecture
  - [x] maintain backward compatibility
- [x] Phase 7: Command System Refactoring (Week 2) ✅ COMPLETE
  - [x] split monolithic commands.lua
  - [x] create orchestration layer
- [x] Phase 8: Core Features Implementation (Weeks 3-4) ✅ COMPLETE
  - [x] multiple account support
  - [x] attachment handling
  - [x] OAuth security enhancements
  - [x] address autocomplete
  - [x] local trash system
  - [x] custom headers
  - [x] image display
- [x] Phase 9: Advanced Features (Weeks 5-6) 🎉 MOSTLY COMPLETE (5/8 features + core scheduling)
  - [x] undo send system ✅ COMPLETE (replaced by unified scheduler)
  - [x] advanced search ✅ COMPLETE
  - [x] email templates ✅ COMPLETE
  - [x] notification system integration ✅ COMPLETE
  - [x] unified email scheduling ✅ CORE COMPLETE (see PHASE_9_NEXT_IMPLEMENTATION.md)
    - [x] Phase 0, 1, 4, 5: Core functionality implemented
    - [ ] Phase 2: Interactive scheduling windows (optional enhancement)
    - [ ] Phase 3: Enhanced queue management UI (optional enhancement)
  - [ ] multiple account views (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] email rules & filters (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] integration features (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] window management (see WINDOW_MANAGEMENT_SPEC.md)
  - [ ] add search feature
- [ ] Phase 10: Integration & Polish (Week 7)
  - [x] nvim freezes while sync is running, for instance as soon as I start nvim ✅ FIXED
    - [x] identified blocking `os.execute` in `oauth.has_token`
    - [x] created async versions: `has_token_async` and `is_valid_async`
    - [x] modified `mbsync.sync` to use async OAuth check
    - [x] added comprehensive startup timing logs with `[STARTUP DEBUG]` markers
  - [x] last sync time not updating in header ✅ FIXED
    - [x] fixed `fetch_folder_count_async` that didn't exist
    - [x] now using synchronous `fetch_folder_count` with binary search
    - [x] correctly shows email counts > 1000 (e.g., "2023 emails")
    - [x] timestamps properly updated after sync
  - [x] auto-sync not starting on startup ✅ FIXED
    - [x] added debug notifications to track initialization
    - [x] verified auto-sync starts with configurable delay
    - [x] integrated with multi-instance coordination
  - [ ] misc
    - [x] fix "**No Breaking Changes**: All improvements must maintain backward compatibility" ✅ FIXED
      - [x] updated spec/README.md to reflect preference for clean architecture over backwards compatibility
      - [ ] remove backwards compatibility
        - [x] searched and added TODOs to mark backwards compatibility elements for removal:
        - [ ] setup/migration.lua: entire migration system (deprecated files, config migrations)
        - [ ] core/commands.lua: compatibility bridge for modular commands  
        - [ ] init.lua: get_keymaps() function maintained for compatibility
        - [ ] core/state.lua: state versioning and migration system
        - [ ] setup/health.lua: old timestamp format detection
        - [ ] utils.lua: optional enhanced utilities import with merge
    - [ ] add search spec file
    - [ ] start compose email in TO field
    - [ ] make drafts openable from sidebar with 'return'
      - [x] created comprehensive specification document: [SAVE_AND_RETURN_TO_DRAFTS.md](spec/SAVE_AND_RETURN_TO_DRAFTS.md)
      - [x] updated phase mapping and README.md to include new spec
      - [ ] subject lines don't show content
      - [ ] drafts should be removed from the 'Drafts' folder when sent
      - [ ] implement Phase 1: Draft detection and display enhancement
      - [ ] implement Phase 2: Draft reopening logic
      - [ ] implement Phase 3: Polish and testing
      - [ ] disable and do not show same footer commands for drafts
    - [x] make 'tab' through fields in drafts work in insert mode only (currently it is only in normal mode) ✅ FIXED
      - [x] changed Tab keymap from normal mode ('n') to insert mode ('i') in email composer
      - [x] now Tab navigates through header fields only when in insert mode, preserving normal mode Tab for buffer navigation
    - [x] there is no confirmation message when running 'gD', 'gA', 'gS' in the sidebar ✅ FIXED
      - [x] added confirmation dialogs to archive_current_email() and spam_current_email() functions
      - [x] now all three operations (delete, archive, spam) show confirmation for single email mode
      - [x] batch mode confirmations were already working correctly
      - [x] fix prompt messages
    - [x] drafts don't save ✅ FIXED
      - [x] fixed duplicate save_draft function definitions
      - [x] fixed draft folder detection to return correct "Drafts" folder name
      - [x] fixed account detection in composer
      - [x] updated CLI syntax for himalaya message save command
      - [x] fixed output parsing for draft save success
      - [x] added comprehensive test suite (5/5 tests passing)
      - [x] 🚧 WORKING: fixing sidebar expansion when draft buffer closes
        - [x] created switch_to_normal_buffer() function with buffer detection
        - [x] updated test to use force_cleanup_compose_buffer() instead of direct buffer deletion
        - [x] testing fix effectiveness
    - [ ] can't delete paused emails
  - [ ] OAuth 2.0 implementation
  - [ ] PGP/GPG encryption
  - [ ] testing infrastructure
  - [ ] performance optimization final pass
  - [ ] final refactor and refinements removing backwards compatibility layers
  - [ ] documentation updates
- [ ] Code Quality Improvements (Ongoing)
  - [x] error handling standardization ✅ (Phase 6)
  - [x] API consistency ✅ (Phase 7)
  - [x] enhanced logging ✅ (Phase 7)
  - [ ] developer experience enhancements

## GUIDELINES

- no need for backwards compatibility or comments about past implementations
- keep the number of modules and commands minimal
  - better to work with and change the existing modules than creating new
  - it is OK to create new modules and commands if there is good reason
- integrate with existing neovim configuration
  - use the notification system described in `nvim/docs/NOTIFICATIONS.md`
  - preserve all existing functionality
- track progress
  - work in phases
  - test changes once complete by running commands and then asking me to test the feature
  - commit changes once testing for a phase is complete
  - keep this TODO.md and the spec files updated as phases are completed, tested, and committed
  - update documentation after all phases are completed and fully tested

## DETAILS

- [x] document existing himalaya implementation ✅ PHASE 1 COMPLETE
  - [x] create a README.md in each directory that:
    - [x] fully describes the modules in that directory
    - [x] briefly describes subdirectories with links to the README.md they each contain
    - [x] includes backlinks to README.md files in the parent directory
  - [x] indicate differences between nixos users and non-nix users where relevant
  - [x] create dependency graph in docs/DEPENDENCIES.md
- [x] refactor existing implementation ✅ PHASES 2-5 COMPLETE
  - [x] remove cruft (HimalayaFastCheck removed)
  - [x] reorganize existing (modularized UI, unified state)
  - [x] establish clean architecture and notification standardization
  - [x] test to confirm all features have been preserved
- [x] features refactor
  - [x] 'Page 2 / 8 | 200 emails' has 200 hard coded (fixed - now shows actual count)
  - [x] 'unlocked' shown in red a few seconds after nvim startup (fixed - replaced echo with exit 0)
  - [x] is /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/ui/confirm.lua used at all? (removed - replaced with vim.ui.select)
  - [x] simplify '⟳ Syncing emails... (4s): 0/1 folders - Connecting' to '⟳ Sync (4s): 0/1 Folders - Connecting'
  - [x] make preview end below the buffer line and above the status line
  - [x] make click between sidebar, preview, and buffers work
  - [x] remove flicker between email previews
  - [x] add footer to email preview
  - [x] make 'gD', 'gA', 'gS' work in email preview
  - [x] make 'q' in the preview to close the preview and exit preview mode
  - [x] make CR in the sidebar start preview mode, and make ESC exit preview mode
  - [x] make CR in the sidebar move the cursor into the preview if preview mode is already started
  - [x] remove extra line after 'gs' sync
  - [x] error on 'gs' sync: [Himalaya] Auth error detected in stdout
  - [x] centralized confirmation prompt
  - [x] `<leader>ak` deletes file and buffer
  - [x] in drafts, 'gs' gives: ⟳ Syncing emails... (21s): Sent 1/6 - Downloaded 178/26621
- [x] cleanup
  - [x] finish /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/ENHANCED_UI_UX_SPEC.md ✅ COMPLETE
    - [x] Updated spec to reflect actual implementation
    - [x] Removed "Himalaya closed" notifications
    - [x] Added debug mode checks to all routine notifications
  - [x] make telescope confirmation messages consistent
  - [x] select with n/N in himalaya is slow
  - [x] make himalaya refresh number of emails on a page with sync
  - [x] can /home/benjamin/.config/nvim/lua/neotex/util/migrate_notifications.lua be removed
  - [x] change "From: benbrastmckie <benbrastmckie@gmail.com>" when emails are composed to "From: Benjamin Brast-McKie <benbrastmckie@gmail.com>"
  - [x] why vimscript: /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/after/syntax/mail.vim

## REFINE REFACTORS

- [x] technical debt
  - [x] update documentation, adding TODOs to mark cruft or areas that could be improved
  - [x] update FEATURES_SPEC.md
  - [x] gather TODOs throughout himalaya/
  - [x] generate refine spec TECH_DEBT.md
  - [x] integrate with notification system
  - [x] generate spec files

## FUTURE FEATURES

### Phase 6: Event System Foundation (Week 1) ✅ COMPLETE

- [x] implement event bus system (orchestration/events.lua)
- [x] define core event constants (core/events.lua)
- [x] add event emissions alongside existing calls
- [x] test event system without breaking existing functionality

### Phase 7: Command System Refactoring (Week 2) ✅ COMPLETE

- [x] split commands.lua into domain modules (ui, email, sync, setup, debug)
- [x] create command orchestration layer
- [x] maintain backward compatibility for all commands
- [x] test all 31+ commands continue working

### Phase 8: Core Features Implementation (Weeks 3-4) ✅ COMPLETE

- [x] **Multiple Account Support**
  - [x] implement account management service
  - [x] create provider detection and templates
  - [x] add account switching UI
  - [x] implement unified inbox view
- [x] **Attachment Handling**
  - [x] create attachment download/view functionality
  - [x] add attachment support in composer
  - [x] implement attachment caching
- [x] **Local Trash System**
  - [x] implement soft delete to local trash
  - [x] add trash viewer UI
  - [x] create retention policies
- [x] **Address Autocomplete**
  - [x] build contact extraction system
  - [x] implement autocomplete UI
  - [x] add contact persistence
- [x] **Custom Headers**
  - [x] full header support and validation
- [x] **Image Display**
  - [x] terminal image rendering

### Phase 9: Advanced Features (Weeks 5-6) 🚧 IN PROGRESS

#### Completed (4/8)

- [x] **Undo Send System**
  - [x] implement send queue with 60-second delay
  - [x] create undo notification UI
  - [x] add queue persistence
- [x] **Advanced Search**
  - [x] implement search query parser with 23+ operators
  - [x] add search operators (from:, to:, subject:, etc.)
  - [x] create search results UI
- [x] **Email Templates**
  - [x] create template management system
  - [x] implement variable substitution and conditionals
  - [x] add template picker UI
- [x] **Notification System Integration**
  - [x] full integration with unified notification system

#### 🎉 COMPLETED Implementation - Unified Email Scheduling (Core Features)

**Status**: All core functionality implemented and tested (5/5 tests passing)

- [x] **Phase 0**: Removed send_queue.lua entirely (breaking changes)
- [x] **Phase 1**: Created comprehensive scheduler.lua module
- [x] **Phase 4**: Updated composer for scheduling-only workflow
- [x] **Phase 5**: Implemented new command structure
- [x] removed "Send Now" option - ALL emails must be scheduled
- [x] minimum 60-second safety delay for all emails
- [x] comprehensive scheduling options: 1min, 5min, 30min, 1h, 2h, tomorrow, custom
- [x] event system integration with orchestration/events.lua
- [x] notification system integration (existing unified system)
- [x] new commands: HimalayaSchedule, HimalayaScheduleCancel, HimalayaScheduleEdit
- [x] composer workflow updated for scheduling-only approach
- [x] test coverage: integration, scheduling functionality, cancellation
- [ ] **Phase 2**: interactive scheduling windows (undo notifications) - OPTIONAL ENHANCEMENT
- [ ] **Phase 3**: enhanced queue management UI - OPTIONAL ENHANCEMENT
- [x] See spec: PHASE_9_NEXT_IMPLEMENTATION.md - CORE COMPLETE

#### Remaining Features

- [ ] **Multiple Account Views** (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] unified inbox showing all accounts
  - [ ] split view for side-by-side accounts
  - [ ] tabbed view for account switching
- [ ] **Email Rules and Filters** (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] rule engine implementation
  - [ ] filter builder UI
  - [ ] automatic actions
- [ ] **Integration Features** (see PHASE_9_REMAINING_FEATURES.md)
  - [ ] task management integration
  - [ ] calendar integration
  - [ ] note-taking integration
- [ ] **Window Management** (see WINDOW_MANAGEMENT_SPEC.md)
  - [ ] predefined layouts
  - [ ] window coordination
  - [ ] interactive resize mode

### Phase 10: Integration & Polish (Week 7)

- [ ] **Performance Optimizations**
  - [ ] implement lazy loading for heavy modules
  - [ ] add performance timing and profiling
  - [ ] optimize state persistence
- [ ] **Testing Infrastructure**
  - [ ] create unit test framework
  - [ ] add integration tests for workflows
  - [ ] implement performance benchmarks
- [ ] **Documentation Updates**
  - [ ] update all README files
  - [ ] create user guide for new features
  - [ ] document architecture changes
- [ ] **OAuth 2.0 Implementation**
  - [ ] enhance token encryption
  - [ ] add multi-provider OAuth support
  - [ ] implement automatic token cleanup
- [ ] **PGP/GPG Encryption** (optional)
  - [ ] email encryption/signing
  - [ ] key management UI
- [ ] **Testing Infrastructure**
  - [ ] create unit test framework
  - [ ] add integration tests for workflows
  - [ ] implement performance benchmarks
- [ ] **Performance Optimizations**
  - [ ] implement lazy loading for heavy modules
  - [ ] add performance timing and profiling
  - [ ] optimize state persistence
- [ ] **Documentation Updates**
  - [ ] update all README files
  - [ ] create user guide for new features
  - [ ] document architecture changes

### Code Quality Improvements (Completed)

- [x] **Error Handling** ✅ (Phase 6)
  - [x] centralized error types and recovery
  - [x] consistent error messaging
- [x] **API Consistency** ✅ (Phase 7)
  - [x] standardize function returns
  - [x] implement facades for all services
- [x] **Enhanced Logging** ✅ (Phase 7)
  - [x] structured logging with handlers
  - [x] debug mode improvements
  - [x] performance timing

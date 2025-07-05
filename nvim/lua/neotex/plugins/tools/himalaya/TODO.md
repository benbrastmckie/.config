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
- [ ] Phase 6: Event System Foundation (Week 1)
  - [ ] implement event-driven architecture
  - [ ] maintain backward compatibility
- [ ] Phase 7: Command System Refactoring (Week 2)
  - [ ] split monolithic commands.lua
  - [ ] create orchestration layer
- [ ] Phase 8: Core Features Implementation (Weeks 3-4)
  - [ ] multiple account support
  - [ ] attachment handling
  - [ ] OAuth security enhancements
  - [ ] address autocomplete
- [ ] Phase 9: Advanced Features (Weeks 5-6)
  - [ ] undo send system
  - [ ] advanced search
  - [ ] email templates
  - [ ] local trash system
- [ ] Phase 10: Integration & Polish (Week 7)
  - [ ] performance optimizations
  - [ ] testing infrastructure
  - [ ] documentation updates
- [ ] Additional Features (Post-Phase 10)
  - [ ] email scheduling
  - [ ] PGP/GPG encryption
  - [ ] email rules & filters
  - [ ] calendar integration
  - [ ] task integration
- [ ] Code Quality Improvements (Ongoing)
  - [ ] error handling standardization
  - [ ] API consistency
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

### Phase 6: Event System Foundation (Week 1)

- [ ] implement event bus system (orchestration/events.lua)
- [ ] define core event constants (core/events.lua)
- [ ] add event emissions alongside existing calls
- [ ] test event system without breaking existing functionality

### Phase 7: Command System Refactoring (Week 2)

- [ ] split commands.lua into domain modules (ui, email, sync, setup)
- [ ] create command orchestration layer
- [ ] maintain backward compatibility for all commands
- [ ] test all 31+ commands continue working

### Phase 8: Core Features Implementation (Weeks 3-4)

- [ ] **Multiple Account Support**
  - [ ] implement account management service
  - [ ] create provider detection and templates
  - [ ] add account switching UI
  - [ ] implement unified inbox view
- [ ] **Attachment Handling**
  - [ ] create attachment download/view functionality
  - [ ] add attachment support in composer
  - [ ] implement attachment caching
- [ ] **OAuth Security**
  - [ ] enhance token encryption
  - [ ] add multi-provider OAuth support
  - [ ] implement automatic token cleanup
- [ ] **Address Autocomplete**
  - [ ] build contact extraction system
  - [ ] implement autocomplete UI
  - [ ] add contact persistence

### Phase 9: Advanced Features (Weeks 5-6)

- [ ] **Undo Send System**
  - [ ] implement send queue with 60-second delay
  - [ ] create undo notification UI
  - [ ] add queue persistence
- [ ] **Advanced Search**
  - [ ] implement search query parser
  - [ ] add search operators (from:, to:, subject:, etc.)
  - [ ] create search results UI
- [ ] **Email Templates**
  - [ ] create template management system
  - [ ] implement variable substitution
  - [ ] add template picker UI
- [ ] **Local Trash System**
  - [ ] implement soft delete to local trash
  - [ ] add trash viewer UI
  - [ ] create retention policies

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

### Additional Features (Post-Phase 10)

- [ ] **Email Scheduling**
  - [ ] scheduled send functionality
  - [ ] recurring email support
- [ ] **PGP/GPG Encryption**
  - [ ] email encryption/signing
  - [ ] key management UI
- [ ] **Email Rules & Filters**
  - [ ] rule engine implementation
  - [ ] filter builder UI
- [ ] **Calendar Integration**
  - [ ] parse calendar invites
  - [ ] respond to meeting requests
- [ ] **Task Integration**
  - [ ] convert emails to tasks
  - [ ] task tracking system

### Code Quality Improvements (Ongoing)

- [ ] **Error Handling**
  - [ ] centralized error types and recovery
  - [ ] consistent error messaging
- [ ] **API Consistency**
  - [ ] standardize function returns
  - [ ] implement facades for all services
- [ ] **Developer Experience**
  - [ ] enhanced logging with rotation
  - [ ] debug mode improvements
  - [ ] performance profiling tools

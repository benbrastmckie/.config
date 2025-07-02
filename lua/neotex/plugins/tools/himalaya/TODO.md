# Himalaya TODO

> PROMPT: Use this document to create a detailed REFACTOR_SPEC.md and FEATURES_SPEC.md

## PLAN

- [x] document existing implementation ✅ PHASE 1 COMPLETE
  - [x] create refactor spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/SAFE_REFACTOR_PLAN.md ✅ COMPLETE
  - [x] implement refactor ✅ PHASES 2-5 COMPLETE
- [ ] add new features to himalaya
  - [x] create new features spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/FEATURES_SPEC.md ✅ COMPLETE
  - [ ] implement new features (see FEATURES_SPEC.md for planned features)
- [ ] complete remaining testing phases
  - [ ] Phase 6: Critical Functionality Testing
  - [ ] Phase 7: Performance Validation
- [ ] update documentation

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
## REMAINING PHASES

### Phase 6: Critical Functionality Testing
- [ ] Email Workflow Testing (basic operations, compose/send, sync operations)
- [ ] State Persistence Testing
- [ ] Multi-Account Testing

### Phase 7: Performance Validation
- [ ] Baseline metrics measurement
- [ ] Post-refactor performance comparison

## FUTURE FEATURES

All planned new features are documented in `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/FEATURES_SPEC.md` including:

### High Priority Features
- Enhanced UI/UX (hover preview, buffer composition, improved confirmations)
- Email Management (attachments, images, custom headers, local trash)
- Sync Improvements (smart status, auto-sync, error recovery)

### Medium Priority Features
- Code Quality Improvements (error handling, API consistency, performance)
- Developer Experience (testing, observability, modularization)

### Low Priority Features  
- Advanced Features (multiple accounts, advanced search, templates, encryption)
- Integration Features (calendar, contacts, tasks, notes)

Refer to FEATURES_SPEC.md for complete details on each planned feature.

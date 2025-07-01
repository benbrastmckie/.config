# Himalaya TODO

> PROMPT: Use this document to create a detailed REFACTOR_SPEC.md and FEATURES_SPEC.md

## PLAN

- [ ] document existing implementation
  - [ ] create refactor spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/REFACTOR_SPEC.md
  - [ ] implement refactor
- [ ] add new features to himalaya
  - [ ] create new features spec in /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/spec/FEATURES_SPEC.md
  - [ ] implement new features
- [ ] update documentation

## GUIDELINES

- no need for backwards compatibility or comments about past implementations
- keep the number of modules and commands minimal
  - better to work with and change the existing modules than creating new
  - it is OK to create new modules and commands if there is good reason
- integrate with existing neovim configuration
  - use the notification system described in `nvim/docs/NOTIFICATIONS.md`
- track progress
  - work in phases
  - test changes once complete by running commands and then asking me to test the feature
  - commit changes once testing for a phase is complete
  - keep this TODO.md and the spec files updated as phases are completed, tested, and committed
  - update documentation after all phases are completed and fully tested

## DETAILS

- [ ] document existing himalaya implementation
  - [ ] create a README.md in each directory that:
    - [ ] fully describes the modules in that directory
    - [ ] briefly describes subdirectories with links to the README.md they each contain
    - [ ] includes backlinks to README.md files in the parent directory
  - [ ] indicate differences between nixos users and non-nix users where relevant
- refactor existing implementation
  - remove cruft
  - reorganize existing
  - test to confirm all features have been preserved
- add new features
  - UI
    - [ ] hover and buffers
      - [ ] hover emails in second sidebar
      - [ ] reply/forward/compose emails in buffers saved in drafts folder
      - delete drafts from drafts folder when discarding
    - [ ] appearances
      - [ ] confirm messages use return/escape
      - [ ] "Himalaya closed" can be removed
      - [ ] "Page 1 | 200 emails" does not reflect the 179 emails in my inbox
  - [ ] EMAIL
    - [ ] sync
      - [ ] remove fast sync
      - [ ] sidebar status for smart_sync
      - [ ] auto_sync when nvim opens
    - [ ] extras
      - [ ] https://github.com/pimalaya/himalaya?tab=readme-ov-file#faq
      - [ ] attachments
      - [ ] images
      - [ ] add header field to email
    - [ ] local trash system
      - [ ] mappings for viewing and recovering trash
    - [ ] autocomplete
      - [ ] addresses in the form: Name <user@domain>

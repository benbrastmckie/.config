# Himalaya TODO

## HIGH LEVEL PLAN

- document existing implementation
- create refactor spec
- implement refactor
- create new features spec
- implement new features
- update documentation

## DETAILS

- documentation
  - [ ] document existing
  - [ ] works with nix and non-nix
- refactor
  - remove cruft
  - reorganize
- new features
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
- [ ] publish plugin

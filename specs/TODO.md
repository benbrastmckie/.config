---
next_project_number: 56
---

# TODO

## Tasks

### 55. Systematically refactor the himalaya module
- **Effort**: TBD
- **Status**: [NOT STARTED]
- **Language**: neovim
- **Dependencies**: None

**Description**: Systematically refactor the himalaya module in neovim config by identifying the intended UX and then designing a complete overhaul which improves the implementation to provide greater functionality (currently it opens and shows inbox for gmail but can't open emails or select/deselect emails, etc.).

### 54. Fix himalaya UI toggle error and review keybindings
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](054_himalaya_ui_toggle_error/reports/research-001.md)
- **Plan**: [implementation-001.md](054_himalaya_ui_toggle_error/plans/implementation-001.md)
- **Completed**: 2026-02-10
- **Summary**: [implementation-summary-20260210.md](054_himalaya_ui_toggle_error/summaries/implementation-summary-20260210.md)

**Description**: Fix himalaya UI toggle error (`attempt to call field 'toggle' (a nil value)` at ui.lua:32) when hitting `<leader>mo`. Research what mappings do, how they could be improved, and identify any bugs or issues to fix.

### 53. Research and implement himalaya multi-email configuration
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](053_himalaya_multi_email_config/reports/research-001.md)
- **Plan**: [implementation-001.md](053_himalaya_multi_email_config/plans/implementation-001.md)
- **Completed**: 2026-02-10
- **Summary**: [implementation-summary-20260210.md](053_himalaya_multi_email_config/summaries/implementation-summary-20260210.md)

**Description**: Research and implement himalaya multi-email account configuration for Protonmail (logos) alongside Gmail in neovim. mbsync logos already works.


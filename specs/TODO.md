---
next_project_number: 57
---

# TODO

## Tasks

### 56. Fix himalaya pagination display and keymap conflicts
- **Effort**: TBD
- **Status**: [RESEARCHED]
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](056_himalaya_pagination_display_fix/reports/research-001.md), [research-002.md](056_himalaya_pagination_display_fix/reports/research-002.md)

**Description**: Fix himalaya pagination where pressing 'n' moves to page 2 but nothing displays, and 'N' is captured by Vim's search navigation instead of previous page. Systematically investigate the pagination mechanism, UI refresh logic, and keymap conflicts to implement an elegant fix that avoids compounding issues.

### 55. Systematically refactor the himalaya module
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](055_himalaya_module_refactor/reports/research-001.md), [research-002.md](055_himalaya_module_refactor/reports/research-002.md)
- **Plan**: [implementation-001.md](055_himalaya_module_refactor/plans/implementation-001.md)
- **Completed**: 2026-02-10
- **Summary**: [implementation-summary-20260210.md](055_himalaya_module_refactor/summaries/implementation-summary-20260210.md)

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


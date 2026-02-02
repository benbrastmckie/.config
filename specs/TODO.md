---
next_project_number: 23
---

# TODO

## Tasks

### 22. Review .claude/ directory for Neovim improvements
- **Effort**: 2-4 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Research**: [research-001.md](specs/22_review_claude_directory_neovim_improvements/reports/research-001.md)
- **Plan**: [implementation-002.md](specs/22_review_claude_directory_neovim_improvements/plans/implementation-002.md)

**Description**: Review .claude/ directory for remaining improvements needed for Neovim configuration focus. After completing tasks 19, 20, and 21 which adapted the system from Lean to Neovim, identify what else needs updating - specifically focusing on context/ files that may need improvement or expansion for the new Neovim maintenance use case.

### 21. Update .claude/ documentation to remove Lean references
- **Effort**: 4-8 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/21_update_claude_docs_neovim_focus/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/21_update_claude_docs_neovim_focus/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/21_update_claude_docs_neovim_focus/summaries/implementation-summary-20260202.md)

**Description**: Update .claude/ documentation to remove Lean references and reflect Neovim focus. Found 128+ files with Lean/theorem/proof references including: .claude/README.md (51 refs), docs/architecture/system-overview.md (14 refs), context/index.md (4 refs), plus extensive refs in docs/guides/, context/core/, context/project/, skills/, agents/, commands/, and rules/. Need systematic review to replace Lean examples with Neovim examples, update architecture descriptions, fix outdated language routing tables, and ensure all documentation accurately reflects the stock Neovim configuration system.

### 20. Update specs/README.md with directory overview
- **Effort**: 0.5-1 hours
- **Status**: [COMPLETED]
- **Language**: general
- **Research**: [research-001.md](specs/20_update_specs_readme_overview/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/20_update_specs_readme_overview/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260201.md](specs/20_update_specs_readme_overview/summaries/implementation-summary-20260201.md)

**Description**: Update specs/README.md to provide a brief overview of the directory contents, noting that numbered project directories accumulate and are archived to specs/archive/ by the /todo command

### 19. Adapt Claude agent system for stock Neovim configuration
- **Effort**: 14-21 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/19_adapt_claude_system_for_stock_neovim/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/19_adapt_claude_system_for_stock_neovim/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/19_adapt_claude_system_for_stock_neovim/summaries/implementation-summary-20260202.md)

**Description**: Adapt the current .claude/ agent system (designed for Lean codebase) to produce a stock .claude/ agent system for Neovim configuration maintenance that can be systematically extended for specific applications


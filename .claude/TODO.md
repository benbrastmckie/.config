# TODO

## In Progress

- [x] **Error Repair Implementation (983)** - Fix 140 logged errors across 7 patterns affecting 10 commands [.claude/specs/983_repair_20251130_100233/plans/001-repair-20251130-100233-plan.md]
  - Report: [001 Error Analysis](.claude/specs/983_repair_20251130_100233/reports/001_error_analysis.md)
  - Report: [002 Simplification Analysis](.claude/specs/983_repair_20251130_100233/reports/002_simplification_analysis.md)
  - Summary: [001 Implementation Iteration 1 Summary](.claude/specs/983_repair_20251130_100233/summaries/001-implementation-iteration-1-summary.md)
- [x] **Fix /repair Command Error Logging Issues (018)** - Fix /repair command state persistence, error logging, and workflow transition issues [.claude/specs/018_repair_repair_20251202_120554/plans/001-repair-repair-20251202-120554-plan.md]
  - Report: [001 Repair Errors Repair](.claude/specs/018_repair_repair_20251202_120554/reports/001-repair-errors-repair.md)
  - Report: [002 Workflow State Analysis](.claude/specs/018_repair_repair_20251202_120554/reports/002-workflow-state-analysis.md)
  - Summary: [001 Implementation Summary](.claude/specs/018_repair_repair_20251202_120554/summaries/001-implementation-summary.md)
- [x] **Lean Command Orchestrator Implementation (026)** - Dedicated /lean command orchestrator for AI-assisted Lean 4 theorem proving [.claude/specs/026_lean_command_orchestrator_implementation/plans/001-lean-command-orchestrator-implementation-plan.md]
  - Report: [001 Lean Command Orchestrator Design](.claude/specs/026_lean_command_orchestrator_implementation/reports/001-lean-command-orchestrator-design.md)
  - Summary: [001 Implementation Summary](.claude/specs/026_lean_command_orchestrator_implementation/summaries/001-implementation-summary.md)
- [x] **Remove Preview Diff Option (041)** - Remove option 4 from nvim claude-code sync utility [.claude/specs/041_nvim_sync_preview_diff/plans/001-preview-diff-plan.md]

## Not Started

- [ ] **.claude/ Infrastructure Refactor (000)** - Systematic refactor of .claude/ infrastructure aligned with Anthropic 2025 best practices [.claude/specs/000_claude_infrastructure_refactor/plans/001-claude-infrastructure-refactor-plan.md]
  - Report: [001 Infrastructure Refactor Analysis](.claude/specs/000_claude_infrastructure_refactor/reports/001-infrastructure-refactor-analysis.md)
- [ ] **/research Command Error Repair (005)** - Fix systematic runtime errors in /research command [.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md]

## Research

Research-only projects (reports without implementation plans):

- [ ] **TODO.md Update Integration Analysis (002)** - Comprehensive analysis of TODO.md update integration across all artifact-creating commands [.claude/specs/002_todo_update_integration_gaps/]
  - Report: [001 TODO.md Update Integration Analysis](.claude/specs/002_todo_update_integration_gaps/reports/001-review-todomd-update-integration-across.md)

- [ ] **Error Analysis Report (017)** - Detailed analysis of critical error patterns and repair strategy [.claude/specs/017_repair_plan_20251202_115442/]
  - Report: [001 Error Analysis Report](.claude/specs/017_repair_plan_20251202_115442/reports/001-error-analysis-report.md)

- [ ] **Lean MCP Command Integration Strategy (025)** - Research on lean-lsp-mcp integration for theorem proving [.claude/specs/025_lean_mcp_command_orchestration_strategy/]
  - Report: [001 Lean MCP Command Orchestration Strategy Research Report](.claude/specs/025_lean_mcp_command_orchestration_strategy/reports/001-lean-mcp-command-integration.md)

- [ ] **Plan Orchestration Failure Analysis (678)** - Analysis of task invocation failures across workflow commands [.claude/specs/678_coordinate_haiku_classification/]
  - Report: [001 Research Report: Plan Orchestration Failure Analysis](.claude/specs/678_coordinate_haiku_classification/reports/001-plan-orchestration-failure-analysis.md)

- [ ] **Command Infrastructure Uniformity Analysis (989)** - Analysis of command infrastructure uniformity across .claude/commands/ [.claude/specs/989_no_name_error/]
  - Report: [001 Command Infrastructure Uniformity Analysis](.claude/specs/989_no_name_error/reports/001-research-the-commands-in-claudecommand.md)
  - Report: [002 Best Practices for Prompt Engineering](.claude/specs/989_no_name_error/reports/002-look-up-the-best-practices-for-prompt-an.md)
  - Report: [003 Anthropic Best Practices Synthesis](.claude/specs/989_no_name_error/reports/003-research-the-information-provided-in.md)

- [ ] **Command-Level TODO.md Tracking Integration Specification (990)** - Specification for command TODO.md tracking integration via delegation pattern [.claude/specs/990_commands_todo_tracking_integration/]
  - Report: [001 Command-Level TODO.md Tracking Integration Specification](.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md)

## Saved

*Manually curated items temporarily deprioritized. Content preserved across /todo updates.*

## Backlog

**Refactoring/Enhancement Ideas**:

- remove /build
- the repair plans don't have the right metadata
- check relevant standards, updating as needed
- Retry semantic directory topic names and other fail-points
- Refactor subagent applications throughout commands
  - Incorporate skills throughout commands
- Make commands update TODO.md automatically
- Make all relevant commands update TODO.md
- Make metadata and summary outputs uniform across artifacts (include directory project numbers)
- /repair to check agreement with .claude/docs/ standards
- **Command optimization and consolidation** - Consolidate fragmented commands (/expand 32->8 blocks, /collapse 29->8 blocks), standardize "Block N" documentation, evaluate initialization patterns [Merged from Plan 882]

## Abandoned

*No abandoned projects.*

## Completed

**December 4, 2025**:

- [x] **Git-Based TODO.md Backup Migration (001)** - Replace file-based TODO.md backups with git commits for cleaner filesystem and better recovery [.claude/specs/001_git_backup_todo_cleanup/plans/001-git-backup-todo-cleanup-plan.md]
- [x] **/todo Command Subagent Delegation (004)** - Refactor /todo command to enforce hard barrier subagent delegation pattern [.claude/specs/004_todo_command_subagent_delegation/plans/001-todo-command-subagent-delegation-plan.md]
- [x] **Plan Command Orchestration Fix (006)** - Fix pseudo-code Task invocations across all workflow commands (system-wide) [.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md]
- [x] **Fix Lean Infoview Keybinding (009)** - Fix non-functional Lean infoview toggle keybinding [.claude/specs/009_nvim_lean_keybinding_infoview/plans/001-nvim-lean-keybinding-infoview-plan.md]
- [x] **Repair Plan Standards Enforcement (010)** - Enforce uniform plan metadata standards across all plan-generating commands [.claude/specs/010_repair_plan_standards_enforcement/plans/001-repair-plan-standards-enforcement-plan.md]
- [x] **/plan Errors Repair (011)** - Repair /plan command error logging and state management issues [.claude/specs/011_repair_plan_20251202_090807/plans/001-repair-plan-20251202-090807-plan.md]
- [x] **Nested .claude/ Directory Creation Fix (012)** - Fix incorrect CLAUDE_PROJECT_DIR path detection in test scripts [.claude/specs/012_nested_claude_dir_creation_fix/plans/001-nested-claude-dir-creation-fix-plan.md]
- [x] **Plan Command Dropdown Duplicates (013)** - Eliminate triple /plan command entries in Claude Code dropdown menu [.claude/specs/013_plan_command_dropdown_duplicates/plans/001-plan-command-dropdown-duplicates-plan.md]
- [x] **/test Command Error Repair (014)** - Fix /test command errors (ERR trap false positives and state machine complexity validation) [.claude/specs/014_repair_test_20251202_100545/plans/001-repair-test-20251202-100545-plan.md]
- [x] **Commands TODO.md Update Integration (015)** - Systematic TODO.md update integration across all commands [.claude/specs/015_commands_todo_update_integration/plans/001-commands-todo-update-integration-plan.md]
- [x] **TODO Command Invocation Fix (016)** - Fix trigger_todo_update() to properly invoke /todo command [.claude/specs/016_todo_command_invocation_fix/plans/001-todo-command-invocation-fix-plan.md]
- [x] **/plan Command Error Fixes (019)** - Fix /plan command bash syntax and state persistence errors [.claude/specs/019_repair_plan_20251201_211758/plans/001-repair-plan-20251201-211758-plan.md]
- [x] **/implement Command Error Fixes (020)** - /implement command error fixes addressing state persistence JSON validation and agent reliability [.claude/specs/020_repair_implement_20251202_003956/plans/001-repair-implement-20251202-003956-plan.md]
- [x] **Plan Progress Tracking Fix (021)** - Integrate checkbox-utils.sh into implementation-executor agent [.claude/specs/021_plan_progress_tracking_fix/plans/001-plan-progress-tracking-fix-plan.md]
- [x] **Lean LSP MCP Neovim Integration (022)** - Integrate lean-lsp-mcp server for AI-assisted theorem proving in Neovim [.claude/specs/022_lean_lsp_mcp_neovim_integration/plans/001-lean-lsp-mcp-neovim-integration-plan.md]
- [x] **/test Command Repair (023)** - Fix critical errors blocking /test command execution [.claude/specs/023_repair_test_20251202_150525/plans/001-repair-test-20251202-150525-plan.md]
- [x] **/repair Workflow Fix (024)** - Fix state transitions, state persistence, and conditionals in /repair workflow [.claude/specs/024_repair_repair_20251202_152829/plans/001-repair-repair-20251202-152829-plan.md]
- [x] **Checkbox Utils Phase Heading Support (027)** - Add dual heading format support to checkbox-utils.sh [.claude/specs/027_checkbox_utils_phase_heading_support/plans/001-checkbox-utils-phase-heading-support-plan.md]
- [x] **Lean Command Parallel Subagent Orchestration (028)** - Implement parallel subagent orchestration for /lean command [.claude/specs/028_lean_subagent_orchestration/plans/001-lean-subagent-orchestration-plan.md]
- [x] **Build Command Removal (029)** - Remove /build command file, documentation, tests, and update all cross-references [.claude/specs/029_build_command_removal/plans/001-build-command-removal-plan.md]
- [x] **Lean Metadata Phase Header Update (030)** - Enhance /lean command flexibility with optional metadata discovery and integrate checkbox-utils.sh [.claude/specs/030_lean_metadata_phase_header_update/plans/001-lean-metadata-phase-header-update-plan.md]
- [x] **Plan Command Format Fix (031)** - Update plan.md Task invocation to explicitly enforce critical format constraints [.claude/specs/031_plan_command_format_fix/plans/001-plan-format-fix.md]
- [x] **Lean Plan Command (032)** - Implement a Lean-specific planning workflow [.claude/specs/032_lean_plan_command/plans/001-lean-plan-command-plan.md]
- [x] **Lean Command Build Improvements (033)** - Implement Lean command build improvements [.claude/specs/033_lean_command_build_improve/plans/001-lean-command-build-improve-plan.md]
- [x] **Lean Command Naming Standardization (034)** - Standardize Lean command naming to use hyphens [.claude/specs/034_lean_command_naming_standardization/plans/001-lean-command-naming-standardization-plan.md]
- [x] **/plan Command Rename to /create-plan (035)** - Rename /plan command to /create-plan [.claude/specs/035_plan_command_rename/plans/001-plan-command-rename-plan.md]
- [x] **/lean-build Command Error Improvement (036)** - Improve /lean-build command error handling [.claude/specs/036_lean_build_error_improvement/plans/001-lean-build-error-improvement-plan.md]
- [x] **Lean Metadata Phase Refactor (037)** - Refactor Lean plan metadata to support per-phase Lean file specifications [.claude/specs/037_lean_metadata_phase_refactor/plans/001-lean-metadata-phase-refactor-plan.md]
- [x] **Nvim Sync Clean Replace Fix (038)** - Fix option 5 (Clean Replace) in nvim claude-code sync utility [.claude/specs/038_nvim_sync_clean_replace/plans/001-nvim-sync-clean-replace-plan.md]
- [x] **Lean-Implement Command Design (039)** - Design unified command for intelligent Lean/software phase routing [.claude/specs/039_lean_implement_command_design/plans/001-lean-implement-command-design-plan.md]
- [x] **Nvim Sync Interactive Mode (040)** - Implement interactive mode (option 3) in nvim claude-code sync utility [.claude/specs/040_nvim_sync_interactive_mode/plans/001-interactive-mode-plan.md]
- [x] **Commands TODO.md Integration Refactor (991)** - Add TODO.md integration to /repair, /errors, /debug commands [.claude/specs/991_commands_todo_tracking_refactor/plans/001-commands-todo-tracking-refactor-plan.md]
- [x] **Fix Bash Syntax Errors, State Persistence Violations, and Agent Reliability (992)** - Error Pattern Remediation [.claude/specs/992_repair_plan_20251201_123734/plans/001-repair-plan-20251201-123734-plan.md]
- [x] **Build Command Workflow Refactor (993)** - Refactor /build command into /implement and /test commands [.claude/specs/993_build_command_workflow_refactor/plans/001-build-command-workflow-refactor-plan.md]
- [x] **/optimize-claude Command Refactor (994)** - Refactor /optimize-claude command into standards-compliant workflow [.claude/specs/994_optimize_claude_command_refactor/plans/001-optimize-claude-refactor-plan.md]
- [x] **/todo Error Repair (995)** - Fix /todo command bash syntax errors and implement systemic improvements [.claude/specs/995_repair_todo_20251201_143930/plans/001-repair-todo-20251201-143930-plan.md]
- [x] **/todo Error Logging Enhancement (996)** - Enhance /todo error logging with dual trap setup and pre-trap buffering [.claude/specs/996_todo_error_logging_improve/plans/001-todo-error-logging-improve-plan.md]
- [x] **Plan Metadata Field Deficiency Fix (997)** - Fix plan metadata field deficiencies in /repair and /revise commands [.claude/specs/997_plan_metadata_field_deficiency/plans/001-plan-metadata-field-deficiency-plan.md]
- [x] **TODO.md Update Pattern Fix (997)** - Fix broken TODO.md update pattern across 5 commands [.claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md]
- [x] **Fix /implement State Persistence Errors (998)** - Fix /implement state persistence errors for WORK_REMAINING variable [.claude/specs/998_repair_implement_20251201_154205/plans/001-repair-implement-20251201-154205-plan.md]
- [x] **/implement Command Persistence Enhancement (999)** - Add /build-style persistence to /implement command [.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md]

# TODO

## In Progress

- [x] **Error Repair Implementation** - Fix 140 logged errors across 7 patterns affecting 10 commands [.claude/specs/983_repair_20251130_100233/plans/001-repair-20251130-100233-plan.md]
  - Report: [001_error_analysis.md](.claude/specs/983_repair_20251130_100233/reports/001_error_analysis.md)
  - Report: [002_simplification_analysis.md](.claude/specs/983_repair_20251130_100233/reports/002_simplification_analysis.md)
  - Summary: [001-implementation-iteration-1-summary.md](.claude/specs/983_repair_20251130_100233/summaries/001-implementation-iteration-1-summary.md)

- [x] **Fix /implement State Persistence Errors** - Convert JSON array format to space-separated scalar in implementer-coordinator agent and /implement command Block 1c [.claude/specs/998_repair_implement_20251201_154205/plans/001-repair-implement-20251201-154205-plan.md]
  - Report: [001-implement-errors-repair.md](.claude/specs/998_repair_implement_20251201_154205/reports/001-implement-errors-repair.md)
  - Report: [002-plan-revision-insights.md](.claude/specs/998_repair_implement_20251201_154205/reports/002-plan-revision-insights.md)
  - Summary: [001-implementation-summary.md](.claude/specs/998_repair_implement_20251201_154205/summaries/001-implementation-summary.md)

## Not Started

- [ ] **.claude/ Infrastructure Refactor** - Systematic refactor of .claude/ infrastructure aligned with Anthropic 2025 best practices [.claude/specs/000_claude_infrastructure_refactor/plans/001-claude-infrastructure-refactor-plan.md]
  - Report: [001-infrastructure-refactor-analysis.md](.claude/specs/000_claude_infrastructure_refactor/reports/001-infrastructure-refactor-analysis.md)

- [ ] **Git-Based TODO.md Backup Migration** - Replace file-based TODO.md backups with git commits for cleaner filesystem and better recovery [.claude/specs/001_git_backup_todo_cleanup/plans/001-git-backup-todo-cleanup-plan.md]
  - Report: [001-backup-patterns-analysis.md](.claude/specs/001_git_backup_todo_cleanup/reports/001-backup-patterns-analysis.md)
  - Summary: [001-implementation-summary.md](.claude/specs/001_git_backup_todo_cleanup/summaries/001-implementation-summary.md)

- [ ] **/research Command Error Repair** - Fix systematic runtime errors in /research command affecting workflow initialization and state restoration [.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md]
  - Report: [001-research-errors-repair.md](.claude/specs/005_repair_research_20251201_212513/reports/001-research-errors-repair.md)
  - Summary: [001-implementation-summary.md](.claude/specs/005_repair_research_20251201_212513/summaries/001-implementation-summary.md)

## Research

Research-only projects (reports without implementation plans):

- [ ] **TODO.md Update Integration Analysis** - Comprehensive analysis of TODO.md update integration across all artifact-creating commands [.claude/specs/002_todo_update_integration_gaps/]
  - Report: [001-review-todomd-update-integration-across.md](.claude/specs/002_todo_update_integration_gaps/reports/001-review-todomd-update-integration-across.md)

- [ ] **Command Infrastructure Uniformity Analysis** - Analysis of command infrastructure uniformity across .claude/commands/ [.claude/specs/989_no_name_error/]
  - Report: [001-research-the-commands-in-claudecommand.md](.claude/specs/989_no_name_error/reports/001-research-the-commands-in-claudecommand.md)
  - Report: [002-look-up-the-best-practices-for-prompt-an.md](.claude/specs/989_no_name_error/reports/002-look-up-the-best-practices-for-prompt-an.md)
  - Report: [003-research-the-information-provided-in.md](.claude/specs/989_no_name_error/reports/003-research-the-information-provided-in.md)

- [ ] **Command-Level TODO.md Tracking Integration Specification** - Specification for command TODO.md tracking integration via delegation pattern [.claude/specs/990_commands_todo_tracking_integration/]
  - Report: [001-i-want-all-commands-in-claudecommands.md](.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md)

## Saved

*Manually curated items temporarily deprioritized. Content preserved across /todo updates.*

## Backlog

**Refactoring/Enhancement Ideas**:

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

### 2025-12-01

- [x] **/todo Command Subagent Delegation** - Refactor /todo command to enforce hard barrier subagent delegation pattern [.claude/specs/004_todo_command_subagent_delegation/plans/001-todo-command-subagent-delegation-plan.md]
  - Report: [001-todo-command-subagent-delegation-analysis.md](.claude/specs/004_todo_command_subagent_delegation/reports/001-todo-command-subagent-delegation-analysis.md)
  - Summary: [001-implementation-summary.md](.claude/specs/004_todo_command_subagent_delegation/summaries/001-implementation-summary.md)

- [x] **/plan Command Error Fixes** - Fix bash syntax and state persistence errors in /plan command [.claude/specs/019_repair_plan_20251201_211758/plans/001-repair-plan-20251201-211758-plan.md]
  - Report: [001-plan-errors-repair.md](.claude/specs/019_repair_plan_20251201_211758/reports/001-plan-errors-repair.md)
  - Summary: [001-implementation-summary.md](.claude/specs/019_repair_plan_20251201_211758/summaries/001-implementation-summary.md)

- [x] **Commands TODO.md Integration Refactor** - Add TODO.md integration to /repair, /errors, /debug commands using delegation pattern [.claude/specs/991_commands_todo_tracking_refactor/plans/001-commands-todo-tracking-refactor-plan.md]
  - Report: [001-gap-analysis-and-implementation-strategy.md](.claude/specs/991_commands_todo_tracking_refactor/reports/001-gap-analysis-and-implementation-strategy.md)
  - Summary: [001-implementation-summary.md](.claude/specs/991_commands_todo_tracking_refactor/summaries/001-implementation-summary.md)

- [x] **Repair Plan: Fix Bash Syntax Errors, State Persistence Violations, and Agent Reliability** - Error Pattern Remediation - /plan Command Reliability [.claude/specs/992_repair_plan_20251201_123734/plans/001-repair-plan-20251201-123734-plan.md]
  - Report: [001-plan-errors-repair.md](.claude/specs/992_repair_plan_20251201_123734/reports/001-plan-errors-repair.md)
  - Report: [002-plan-revision-standards-alignment.md](.claude/specs/992_repair_plan_20251201_123734/reports/002-plan-revision-standards-alignment.md)
  - Summary: [001-implementation-summary.md](.claude/specs/992_repair_plan_20251201_123734/summaries/001-implementation-summary.md)

- [x] **Build Command Workflow Refactor** - Refactor /build command into /implement and /test commands with summary-based handoff [.claude/specs/993_build_command_workflow_refactor/plans/001-build-command-workflow-refactor-plan.md]
  - Report: [001-build-command-analysis.md](.claude/specs/993_build_command_workflow_refactor/reports/001-build-command-analysis.md)
  - Report: [002-implement-test-integration.md](.claude/specs/993_build_command_workflow_refactor/reports/002-implement-test-integration.md)
  - Summary: [001-iteration-1-implementation-summary.md](.claude/specs/993_build_command_workflow_refactor/summaries/001-iteration-1-implementation-summary.md)
  - Summary: [002-iteration-2-implementation-summary.md](.claude/specs/993_build_command_workflow_refactor/summaries/002-iteration-2-implementation-summary.md)
  - Summary: [003-iteration-3-implementation-summary.md](.claude/specs/993_build_command_workflow_refactor/summaries/003-iteration-3-implementation-summary.md)

- [x] **/optimize-claude Command Refactor** - Refactor /optimize-claude command into standards-compliant workflow [.claude/specs/994_optimize_claude_command_refactor/plans/001-optimize-claude-refactor-plan.md]
  - Report: [001_optimize_claude_refactor_research.md](.claude/specs/994_optimize_claude_command_refactor/reports/001_optimize_claude_refactor_research.md)
  - Summary: [implementation_summary_001.md](.claude/specs/994_optimize_claude_command_refactor/summaries/implementation_summary_001.md)

- [x] **/todo Errors Repair** - Fix /todo command bash syntax errors and implement systemic improvements [.claude/specs/995_repair_todo_20251201_143930/plans/001-repair-todo-20251201-143930-plan.md]
  - Report: [001-todo-errors-repair.md](.claude/specs/995_repair_todo_20251201_143930/reports/001-todo-errors-repair.md)
  - Report: [002-plan-conformance-analysis.md](.claude/specs/995_repair_todo_20251201_143930/reports/002-plan-conformance-analysis.md)
  - Summary: [001-implementation-iteration-1-summary.md](.claude/specs/995_repair_todo_20251201_143930/summaries/001-implementation-iteration-1-summary.md)
  - Summary: [002-implementation-iteration-2-summary.md](.claude/specs/995_repair_todo_20251201_143930/summaries/002-implementation-iteration-2-summary.md)

- [x] **/todo Error Logging Enhancement** - Enhance /todo error logging with dual trap setup and pre-trap buffering [.claude/specs/996_todo_error_logging_improve/plans/001-todo-error-logging-improve-plan.md]
  - Report: [001-todo-error-logging-analysis.md](.claude/specs/996_todo_error_logging_improve/reports/001-todo-error-logging-analysis.md)
  - Summary: [001-todo-error-logging-implementation-summary.md](.claude/specs/996_todo_error_logging_improve/summaries/001-todo-error-logging-implementation-summary.md)

- [x] **Plan Metadata Field Deficiency Fix** - Fix plan metadata field deficiencies in /repair and /revise commands [.claude/specs/997_plan_metadata_field_deficiency/plans/001-plan-metadata-field-deficiency-plan.md]
  - Report: [001-plan-metadata-deficiency-research.md](.claude/specs/997_plan_metadata_field_deficiency/reports/001-plan-metadata-deficiency-research.md)
  - Report: [002-uniform-plan-creation-research.md](.claude/specs/997_plan_metadata_field_deficiency/reports/002-uniform-plan-creation-research.md)
  - Summary: [001-implementation-summary.md](.claude/specs/997_plan_metadata_field_deficiency/summaries/001-implementation-summary.md)

- [x] **TODO.md Update Pattern Fix** - Fix broken TODO.md update pattern across 5 commands [.claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md]
  - Report: [001-todo-update-pattern-analysis.md](.claude/specs/997_todo_update_pattern_fix/reports/001-todo-update-pattern-analysis.md)
  - Summary: [001-implementation-summary.md](.claude/specs/997_todo_update_pattern_fix/summaries/001-implementation-summary.md)

- [x] **/implement Command Persistence Enhancement** - Add /build-style persistence to /implement command [.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md]
  - Report: [001-build-implement-persistence-research.md](.claude/specs/999_build_implement_persistence/reports/001-build-implement-persistence-research.md)
  - Report: [002-standards-compliance-review.md](.claude/specs/999_build_implement_persistence/reports/002-standards-compliance-review.md)
  - Summary: [001-implementation-summary.md](.claude/specs/999_build_implement_persistence/summaries/001-implementation-summary.md)

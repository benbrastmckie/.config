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
- [x] **Create-Plan Research Delegation Refactor (1000)** - Refactor /create-plan command to delegate research phase to dedicated research agent [.claude/specs/1000_create_plan_research_delegation/plans/001-create-plan-research-delegation-plan.md]
  - Report: [001 Create-Plan Research Delegation Analysis](.claude/specs/1000_create_plan_research_delegation/reports/001-create-plan-research-delegation-analysis.md)

## Not Started

- [ ] **.claude/ Infrastructure Refactor (000)** - Systematic refactor of .claude/ infrastructure aligned with Anthropic 2025 best practices [.claude/specs/000_claude_infrastructure_refactor/plans/001-claude-infrastructure-refactor-plan.md]
  - Report: [001 Infrastructure Refactor Analysis](.claude/specs/000_claude_infrastructure_refactor/reports/001-infrastructure-refactor-analysis.md)
- [ ] **/research Command Error Repair (005)** - Fix systematic runtime errors in /research command [.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md]
- [ ] **Fix /create-plan Task Delegation (045)** - Fix /create-plan task delegation failures and improve error handling [.claude/specs/045_create_plan_delegation_failure/plans/001-fix-task-delegation-plan.md]
  - Report: [001 Task Delegation Failure Analysis](.claude/specs/045_create_plan_delegation_failure/reports/001-task-delegation-failure-analysis.md)

## Research

Research-only projects (reports without implementation plans):

- [ ] **TODO.md Update Integration Analysis (002)** - Comprehensive analysis of TODO.md update integration across all artifact-creating commands [.claude/specs/002_todo_update_integration_gaps/]
  - Report: [001 TODO.md Update Integration Analysis](.claude/specs/002_todo_update_integration_gaps/reports/001-review-todomd-update-integration-across.md)

- [ ] **Error Analysis Report (017)** - Detailed analysis of critical error patterns and repair strategy [.claude/specs/017_repair_plan_20251202_115442/]
  - Report: [001 Error Analysis Report](.claude/specs/017_repair_plan_20251202_115442/reports/001-error-analysis-report.md)

- [ ] **Lean MCP Command Integration Strategy (025)** - Research on lean-lsp-mcp integration for theorem proving [.claude/specs/025_lean_mcp_command_orchestration_strategy/]
  - Report: [001 Lean MCP Command Orchestration Strategy Research Report](.claude/specs/025_lean_mcp_command_orchestration_strategy/reports/001-lean-mcp-command-integration.md)

- [ ] **Phase Counting Regex Bug (052)** - Bug analysis for phase counting regex in checkbox utilities [.claude/specs/052_phase_counting_regex_fix/]
  - Report: [001 Phase Counting Regex Bug Research Report](.claude/specs/052_phase_counting_regex_fix/reports/001-phase-counting-regex-bug-research-report.md)

- [ ] **Lean-Implement Command Error Analysis (054)** - Analysis of errors in /lean-implement command execution [.claude/specs/054_lean_implement_error_analysis/]
  - Report: [001 Research Report: /lean-implement Command Error Analysis](.claude/specs/054_lean_implement_error_analysis/reports/001-research-report-lean-implement-command-error-analysis.md)

- [ ] **Plan Orchestration Failure Analysis (678)** - Analysis of task invocation failures across workflow commands [.claude/specs/678_coordinate_haiku_classification/]
  - Report: [001 Research Report: Plan Orchestration Failure Analysis](.claude/specs/678_coordinate_haiku_classification/reports/001-plan-orchestration-failure-analysis.md)

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

*Completed projects removed as of 2025-12-05. 52 completed directories cleaned up.*

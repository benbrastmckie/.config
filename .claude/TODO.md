# TODO

## In Progress

- [x] **Fix /repair command state persistence, error logging, and workflow transition is** - Fix /repair command state persistence, error logging, and workflow transition issues [.claude/specs/018_repair_repair_20251202_120554/]
  - Report: [001-Repair-Errors-Repair](.claude/specs/018_repair_repair_20251202_120554/reports/001-repair-errors-repair.md)
  - Report: [002-Repair-Plan-Standards-Conformance-Research](.claude/specs/018_repair_repair_20251202_120554/reports/002-repair-plan-standards-conformance-research.md)
  - Summary: [001-Implementation-Summary](.claude/specs/018_repair_repair_20251202_120554/summaries/001-implementation-summary.md)
- [x] **Dedicated `/lean` command orchestrator for AI-assisted Lean 4 theorem proving wi** - Dedicated `/lean` command orchestrator for AI-assisted Lean 4 theorem proving with lean-lsp-mcp inte [.claude/specs/026_lean_command_orchestrator_implementation/]
  - Report: [001-Lean-Command-Orchestrator-Design](.claude/specs/026_lean_command_orchestrator_implementation/reports/001-lean-command-orchestrator-design.md)
  - Summary: [001-Lean-Command-Implementation-Summary](.claude/specs/026_lean_command_orchestrator_implementation/summaries/001-lean-command-implementation-summary.md)
- [x] **Fix research-coordinator agent to use imperative Task directives instead of docu** - Fix research-coordinator agent to use imperative Task directives instead of documentation examples [.claude/specs/029_research_coordinator_task_directives/]
  - Report: [001-Root-Cause-Analysis](.claude/specs/029_research_coordinator_task_directives/reports/001-root-cause-analysis.md)
  - Summary: [001-Implementation-Summary](.claude/specs/029_research_coordinator_task_directives/summaries/001-implementation-summary.md)
- [x] **Fix /lean-plan command to generate plans with correct phase heading format (### ** - Fix /lean-plan command to generate plans with correct phase heading format (### not ##), phase metad [.claude/specs/030_lean_plan_format_metadata_fix/]
  - Report: [001-Lean-Plan-Format-Issues](.claude/specs/030_lean_plan_format_metadata_fix/reports/001-lean-plan-format-issues.md)
  - Report: [002-Correct-Plan-Format-Reference](.claude/specs/030_lean_plan_format_metadata_fix/reports/002-correct-plan-format-reference.md)
  - Report: [003-Lean-Plan-Architect-Analysis](.claude/specs/030_lean_plan_format_metadata_fix/reports/003-lean-plan-architect-analysis.md)
  - Summary: [001-Implementation-Summary](.claude/specs/030_lean_plan_format_metadata_fix/summaries/001-implementation-summary.md)
  - Summary: [Implementation Phase10 Summary](.claude/specs/030_lean_plan_format_metadata_fix/summaries/implementation_phase10_summary.md)
- [x] **Fix research-coordinator agent Task invocation failures and enhance orchestrator** - Fix research-coordinator agent Task invocation failures and enhance orchestrator validation patterns [.claude/specs/038_debug_command_fix/]
  - Report: [001-Research-Coordinator-Execution-Failure](.claude/specs/038_debug_command_fix/reports/001-research-coordinator-execution-failure.md)
  - Report: [002-Code-Standards-Compliance](.claude/specs/038_debug_command_fix/reports/002-code-standards-compliance.md)
  - Report: [003-Agent-Enhancement-Fix-Strategy](.claude/specs/038_debug_command_fix/reports/003-agent-enhancement-fix-strategy.md)
  - Summary: [001-Debug-Command-Fix-Implementation-Summary](.claude/specs/038_debug_command_fix/summaries/001-debug-command-fix-implementation-summary.md)
- [x] **Fix research-coordinator agent skipping Task invocations in STEP 3** - Refactor research-coordinator.md STEP 3 to use concrete Bash-generated Task invocations, add pre-exe [.claude/specs/060_coordinator_research_incomplete_fix/]
  - Report: [001-Coordinator-Early-Return-Root-Cause](.claude/specs/060_coordinator_research_incomplete_fix/reports/001-coordinator-early-return-root-cause.md)
- [x] **Error Log Analysis and Repair** - Fix 140 logged errors across 7 error patterns affecting 10 commands [.claude/specs/983_repair_20251130_100233/]
  - Report: [001 Error Analysis](.claude/specs/983_repair_20251130_100233/reports/001_error_analysis.md)
  - Report: [002 Simplification Analysis](.claude/specs/983_repair_20251130_100233/reports/002_simplification_analysis.md)
  - Summary: [001-Implementation-Iteration-1-Summary](.claude/specs/983_repair_20251130_100233/summaries/001-implementation-iteration-1-summary.md)

## Not Started

- [ ] **Systematic refactor of .claude/ infrastructure aligned with Anthropic 2025 best ** - Context management, example expansion, XML structure adoption, library consolidation, documentation  [.claude/specs/000_claude_infrastructure_refactor/]
  - Report: [001-Infrastructure-Refactor-Analysis](.claude/specs/000_claude_infrastructure_refactor/reports/001-infrastructure-refactor-analysis.md)
- [ ] **Extend /todo command to support multi-file TODO.md tracking via CLAUDE.md standa** - Extend /todo command to support multi-file TODO.md tracking via CLAUDE.md standards discovery [.claude/specs/014_todo_standards_multifile/]
  - Report: [001-Todo-Standards-Multifile-Analysis](.claude/specs/014_todo_standards_multifile/reports/001-todo-standards-multifile-analysis.md)
- [ ] **Implementation Plan: Implement Plan Completion Synchronization** - Implementation Plan: Implement Plan Completion Synchronization [.claude/specs/021_implement_plan_completion_sync/]
  - Report: [001-Implement-Plan-Completion-Sync-Analysis](.claude/specs/021_implement_plan_completion_sync/reports/001-implement-plan-completion-sync-analysis.md)
  - Summary: [001-Implement-Plan-Completion-Sync-Summary](.claude/specs/021_implement_plan_completion_sync/summaries/001-implement-plan-completion-sync-summary.md)
- [ ] **Implementation Plan: /revise Command Workflow State Fix** - Implementation Plan: /revise Command Workflow State Fix [.claude/specs/035_revise_command_workflow_state_fix/]
  - Report: [001-Root-Cause-Analysis](.claude/specs/035_revise_command_workflow_state_fix/reports/001-root-cause-analysis.md)
  - Report: [002-Standards-Compliance-Fix](.claude/specs/035_revise_command_workflow_state_fix/reports/002-standards-compliance-fix.md)
  - Summary: [001-Implementation-Summary](.claude/specs/035_revise_command_workflow_state_fix/summaries/001-implementation-summary.md)
- [ ] **Implementation Plan: Plan Metadata Dependencies Fix** - Implementation Plan: Plan Metadata Dependencies Fix [.claude/specs/036_plan_metadata_dependencies_fix/]
  - Report: [001-Lean-Plan-Error-Diagnosis](.claude/specs/036_plan_metadata_dependencies_fix/reports/001-lean-plan-error-diagnosis.md)
  - Report: [002-Plan-Metadata-Dependencies](.claude/specs/036_plan_metadata_dependencies_fix/reports/002-plan-metadata-dependencies.md)
  - Report: [003-Infrastructure-Standards-Integration](.claude/specs/036_plan_metadata_dependencies_fix/reports/003-infrastructure-standards-integration.md)
  - Summary: [001-Implementation-Summary](.claude/specs/036_plan_metadata_dependencies_fix/summaries/001-implementation-summary.md)
- [ ] **Research Coordinator Agent Invocation Fix Implementation Plan** - Research Coordinator Agent Invocation Fix Implementation Plan [.claude/specs/037_research_coordinator_invocation_fix/]
  - Report: [001-Task-Tool-Agent-Invocation](.claude/specs/037_research_coordinator_invocation_fix/reports/001-task-tool-agent-invocation.md)
  - Report: [002-Pseudo-Code-Pattern-Recognition](.claude/specs/037_research_coordinator_invocation_fix/reports/002-pseudo-code-pattern-recognition.md)
  - Report: [003-Agent-Error-Handling-Fallback](.claude/specs/037_research_coordinator_invocation_fix/reports/003-agent-error-handling-fallback.md)
  - Summary: [001-Implementation-Summary](.claude/specs/037_research_coordinator_invocation_fix/summaries/001-implementation-summary.md)
- [ ] **Fix Task tool delegation failure in /create-plan command so subagents actually e** - Fix Task tool delegation failure in /create-plan command so subagents actually execute [.claude/specs/045_create_plan_delegation_failure/]
  - Report: [001-Task-Delegation-Failure-Analysis](.claude/specs/045_create_plan_delegation_failure/reports/001-task-delegation-failure-analysis.md)
- [ ] **Implement coordinator-triggered plan revision workflow, wave-based full plan del** - Implement coordinator-triggered plan revision workflow, wave-based full plan delegation, and compreh [.claude/specs/047_lean_implement_coordinator_waves/]
  - Report: [001-Lean-Coordinator-Invocation](.claude/specs/047_lean_implement_coordinator_waves/reports/001-lean-coordinator-invocation.md)
  - Report: [002-Parallel-Wave-Dependency-Management](.claude/specs/047_lean_implement_coordinator_waves/reports/002-parallel-wave-dependency-management.md)
  - Report: [003-Subagent-Discovery-Plan-Revision](.claude/specs/047_lean_implement_coordinator_waves/reports/003-subagent-discovery-plan-revision.md)
  - Summary: [001-Lean-Implement-Coordinator-Waves-Iteration-1-Summary](.claude/specs/047_lean_implement_coordinator_waves/summaries/001-lean-implement-coordinator-waves-iteration-1-summary.md)
  - Summary: [001-Lean-Implement-Coordinator-Waves-Iteration-2-Summary](.claude/specs/047_lean_implement_coordinator_waves/summaries/001-lean-implement-coordinator-waves-iteration-2-summary.md)
- [ ] **Fix nested single-quote collision in TermExec command causing recipe execution f** - Fix nested single-quote collision in TermExec command causing recipe execution failure [.claude/specs/048_goose_picker_create_plan_output_debug/]
  - Report: [001-Goose-Picker-Quote-Nesting-Analysis](.claude/specs/048_goose_picker_create_plan_output_debug/reports/001-goose-picker-quote-nesting-analysis.md)
- [ ] **Implementation Plan: Lean-Implement Coordinator Delegation Optimization** - Implementation Plan: Lean-Implement Coordinator Delegation Optimization [.claude/specs/051_lean_implement_coordinator_delegation/]
  - Report: [001-Lean-Implement-Output-Analysis](.claude/specs/051_lean_implement_coordinator_delegation/reports/001-lean-implement-output-analysis.md)
  - Report: [001-Root-Cause-Analysis](.claude/specs/051_lean_implement_coordinator_delegation/reports/001-root-cause-analysis.md)
  - Report: [002-Context-Delegation-Strategies](.claude/specs/051_lean_implement_coordinator_delegation/reports/002-context-delegation-strategies.md)
  - Summary: [001-Implementation-Summary](.claude/specs/051_lean_implement_coordinator_delegation/summaries/001-implementation-summary.md)
- [ ] **Fix recipe parameter prompting in Neovim Goose picker** - Fix recipe parameter prompting in Neovim Goose picker [.claude/specs/055_goose_nvim_recipe_topic_prompt/]
  - Report: [001-Goose-Nvim-Recipe-Topic-Prompt-Analysis](.claude/specs/055_goose_nvim_recipe_topic_prompt/reports/001-goose-nvim-recipe-topic-prompt-analysis.md)
  - Summary: [001-Conversational-Recipe-Params](.claude/specs/055_goose_nvim_recipe_topic_prompt/summaries/001-conversational-recipe-params.md)
- [ ] **Refactor goose.nvim configuration to use split windows instead of floating windo** - Refactor goose.nvim configuration to use split windows instead of floating windows for sidebar navig [.claude/specs/057_goose_sidebar_split_refactor/]
  - Report: [001-Split-Window-Ui-Implementation](.claude/specs/057_goose_sidebar_split_refactor/reports/001-split-window-ui-implementation.md)
  - Report: [002-Window-Config-Schema](.claude/specs/057_goose_sidebar_split_refactor/reports/002-window-config-schema.md)
  - Report: [003-Split-Navigation-Integration](.claude/specs/057_goose_sidebar_split_refactor/reports/003-split-navigation-integration.md)
- [ ] **Implementation Plan: Complete Avante Plugin Removal** - Implementation Plan: Complete Avante Plugin Removal [.claude/specs/058_remove_avante_nvim_config/]
  - Report: [001-Avante-Config-Removal](.claude/specs/058_remove_avante_nvim_config/reports/001-avante-config-removal.md)
  - Report: [002-Avante-Docs-Removal](.claude/specs/058_remove_avante_nvim_config/reports/002-avante-docs-removal.md)
  - Report: [003-Avante-Codebase-Cleanup](.claude/specs/058_remove_avante_nvim_config/reports/003-avante-codebase-cleanup.md)
- [ ] **Fix phase marker updates in /lean-implement delegation chain** - Fix phase marker updates in /lean-implement delegation chain [.claude/specs/062_subagent_phase_update_debug/]
  - Report: [001-Root-Cause-Analysis](.claude/specs/062_subagent_phase_update_debug/reports/001-root-cause-analysis.md)
- [ ] **Implementation Plan: goose.nvim Integration with Gemini CLI and Claude Code Max** - Implementation Plan: goose.nvim Integration with Gemini CLI and Claude Code Max [.claude/specs/992_nvim_ai_agent_plugin_integration/]
  - Report: [001-Nvim-Ai-Agent-Plugin-Integration-Analysis](.claude/specs/992_nvim_ai_agent_plugin_integration/reports/001-nvim-ai-agent-plugin-integration-analysis.md)
  - Report: [002-Which-Key-Ai-Mapping-Consolidation](.claude/specs/992_nvim_ai_agent_plugin_integration/reports/002-which-key-ai-mapping-consolidation.md)
  - Report: [Revision Goose Nvim Integration Research](.claude/specs/992_nvim_ai_agent_plugin_integration/reports/revision_goose_nvim_integration_research.md)
  - Summary: [001-Implementation-Summary](.claude/specs/992_nvim_ai_agent_plugin_integration/summaries/001-implementation-summary.md)
- [ ] **Fork goose.nvim locally and implement split window support with toggleable right** - Replace floating windows with configurable split-based sidebar featuring width persistence, dual-pan [.claude/specs/995_goose_split_sidebar_persist/]
  - Report: [001-Goose-Split-Sidebar-Persist-Analysis](.claude/specs/995_goose_split_sidebar_persist/reports/001-goose-split-sidebar-persist-analysis.md)

## Research

Research-only projects (reports without implementation plans):

- [ ] **TODO.md Update Integration Analysis: Command Coverage and Implementation Gaps** - This report provides a comprehensive analysis of TODO.md update integration across all artifact-crea [.claude/specs/002_todo_update_integration_gaps/]
  - Report: [001-Review-Todomd-Update-Integration-Across](.claude/specs/002_todo_update_integration_gaps/reports/001-review-todomd-update-integration-across.md)
- [ ] **Research Coordinator Integration for /create-plan Command: Gap Analysis and Enhancement Opportunities** - - **Date**: 2025-12-08 [.claude/specs/011_create_plan_research_coordinator/]
  - Report: [001-I-Want-The-Create-Plan-Command-In-Clau](.claude/specs/011_create_plan_research_coordinator/reports/001-i-want-the-create-plan-command-in-clau.md)
- [ ] **Research Report: Claude Configuration Agent Optimization** - **Date**: 2025-12-08 [.claude/specs/015_claude_config_agent_optimization/]
  - Report: [001-Research-My-Claudecommands-And-Suppor](.claude/specs/015_claude_config_agent_optimization/reports/001-research-my-claudecommands-and-suppor.md)
- [ ] **Error Analysis Report** - - **Date**: 2025-12-02 [.claude/specs/017_repair_plan_20251202_115442/]
  - Report: [001-Plan-Errors-Repair](.claude/specs/017_repair_plan_20251202_115442/reports/001-plan-errors-repair.md)
- [ ] **Lean MCP Command Orchestration Strategy Research Report** - **Date**: 2025-12-02 [.claude/specs/025_lean_mcp_command_orchestration_strategy/]
  - Report: [001-Lean-Mcp-Command-Integration](.claude/specs/025_lean_mcp_command_orchestration_strategy/reports/001-lean-mcp-command-integration.md)
- [ ] **Phase Counting Regex Bug Research Report** - The phase counting regex in implement.md Block 1d uses `^### Phase` which matches false positives li [.claude/specs/052_phase_counting_regex_fix/]
  - Report: [001-Phase-Counting-Regex-Research](.claude/specs/052_phase_counting_regex_fix/reports/001-phase-counting-regex-research.md)
- [ ] **Research Report: /lean-implement Command Error Analysis** - **Date**: 2024-12-04 [.claude/specs/054_lean_implement_error_analysis/]
  - Report: [001-Lean-Implement-Error-Root-Cause](.claude/specs/054_lean_implement_error_analysis/reports/001-lean-implement-error-root-cause.md)
- [ ] **Research Report: /plan Command Orchestration Failure Analysis** - **Report ID**: 001-plan-command-orchestration-failure [.claude/specs/678_coordinate_haiku_classification/]
  - Report: [001-Plan-Command-Orchestration-Failure](.claude/specs/678_coordinate_haiku_classification/reports/001-plan-command-orchestration-failure.md)
- [ ] **Command-Level TODO.md Tracking Integration Specification** - This specification defines how all commands in `.claude/commands/` should integrate with `/home/benj [.claude/specs/990_commands_todo_tracking_integration/]
  - Report: [001-I-Want-All-Commands-In-Claudecommands](.claude/specs/990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md)
- [ ] **Lean Implement Wave Coordinator Analysis** - This report analyzes the current `/lean-implement` workflow and proposes architectural improvements  [.claude/specs/991_lean_implement_wave_coordinator/]
  - Report: [001-Lean-Implement-Wave-Coordinator-Analysis](.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md)
- [ ] **Research Report: Implementing Toggleable Sidebar for goose.nvim** - **Date**: 2025-12-05 [.claude/specs/994_sidebar_toggle_research_nvim/]
  - Report: [001-Research-What-It-Would-Take-Implement-Th](.claude/specs/994_sidebar_toggle_research_nvim/reports/001-research-what-it-would-take-implement-th.md)
- [ ] **Claude Code to Goose Migration Research Report** - - **Date**: 2025-12-05 [.claude/specs/996_goose_claude_code_port/]
  - Report: [001-Goose-Claude-Code-Port-Research](.claude/specs/996_goose_claude_code_port/reports/001-goose-claude-code-port-research.md)

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

- [x] **Implement test feature following command-based architecture patterns** - Implement test feature following command-based architecture patterns [.claude/specs/031_test_feature/]
  - Report: [001-Feature-Research](.claude/specs/031_test_feature/reports/001-feature-research.md)

## Completed

### 2025-12-09

- [x] **Fix goose.nvim Gemini provider configuration to enable AI-powered sidebar with r** - Fix goose.nvim Gemini provider configuration to enable AI-powered sidebar with recipe support [.claude/specs/004_goose_nvim_gemini_config/]
  - Report: [001-Goose-Nvim-Gemini-Config-Analysis](.claude/specs/004_goose_nvim_gemini_config/reports/001-goose-nvim-gemini-config-analysis.md)
  - Summary: [001-Implementation-Summary](.claude/specs/004_goose_nvim_gemini_config/summaries/001-implementation-summary.md)
- [x] **Fix systematic runtime errors in /research command and related workflow commands** - repair [.claude/specs/005_repair_research_20251201_212513/]
  - Report: [001-Research-Errors-Repair](.claude/specs/005_repair_research_20251201_212513/reports/001-research-errors-repair.md)
  - Summary: [001-Implement-Summary](.claude/specs/005_repair_research_20251201_212513/summaries/001-implement-summary.md)
- [x] **Optimize /lean-implement command performance and infrastructure integration** - Major refactor of Blocks 1a-classify and 1b for wave analysis and parallel Task invocation [.claude/specs/006_optimize_lean_implement_command/]
  - Report: [001-Optimize-Lean-Implement-Command-Analysis](.claude/specs/006_optimize_lean_implement_command/reports/001-optimize-lean-implement-command-analysis.md)
  - Summary: [001-Optimize-Lean-Implement-Implementation-Summary](.claude/specs/006_optimize_lean_implement_command/summaries/001-optimize-lean-implement-implementation-summary.md)
- [x] **Add research-coordinator agent to /lean-plan for parallel multi-topic research o** - Add research-coordinator agent to /lean-plan for parallel multi-topic research orchestration [.claude/specs/009_research_coordinator_agents/]
  - Report: [001-Research-Coordinator-Agents-Analysis](.claude/specs/009_research_coordinator_agents/reports/001-research-coordinator-agents-analysis.md)
  - Summary: [001 Implementation Summary Iteration 1](.claude/specs/009_research_coordinator_agents/summaries/001_implementation_summary_iteration_1.md)
  - Summary: [002 Implementation Summary Iteration 2](.claude/specs/009_research_coordinator_agents/summaries/002_implementation_summary_iteration_2.md)
- [x] **Fix plan completion workflow in /implement command to update metadata status and** - Fix plan completion workflow in /implement command to update metadata status and success criteria [.claude/specs/010_implement_plan_completion_fix/]
  - Report: [001-Implement-Plan-Completion-Fix-Analysis](.claude/specs/010_implement_plan_completion_fix/reports/001-implement-plan-completion-fix-analysis.md)
  - Summary: [001-Implement-Plan-Completion-Fix-Summary](.claude/specs/010_implement_plan_completion_fix/summaries/001-implement-plan-completion-fix-summary.md)
- [x] **Fix 29 logged errors in /research command (4 critical patterns: agent failures, ** - Fix 29 logged errors in /research command (4 critical patterns: agent failures, sourcing issues, pat [.claude/specs/012_repair_research_20251208_122753/]
  - Report: [001-Research-Errors-Repair](.claude/specs/012_repair_research_20251208_122753/reports/001-research-errors-repair.md)
  - Report: [Revision-Analysis-Research-Command](.claude/specs/012_repair_research_20251208_122753/reports/revision-analysis-research-command.md)
  - Summary: [001-Implementation-Summary](.claude/specs/012_repair_research_20251208_122753/summaries/001-implementation-summary.md)
- [x] **Complete research-coordinator integration across ALL planning commands and imple** - Complete research-coordinator integration across ALL planning commands and implement advanced resear [.claude/specs/013_research_coordinator_gaps_uniformity/]
  - Report: [001-Research-Coordinator-Gaps-Uniformity-Analysis](.claude/specs/013_research_coordinator_gaps_uniformity/reports/001-research-coordinator-gaps-uniformity-analysis.md)
  - Report: [002-Deferred-Topics-Analysis](.claude/specs/013_research_coordinator_gaps_uniformity/reports/002-deferred-topics-analysis.md)
  - Summary: [001-Iteration-1-Implementation-Summary](.claude/specs/013_research_coordinator_gaps_uniformity/summaries/001-iteration-1-implementation-summary.md)
  - Summary: [001 Phase1 Implementation Analysis](.claude/specs/013_research_coordinator_gaps_uniformity/summaries/001_phase1_implementation_analysis.md)
- [x] **Optimize /lean-plan and /lean-implement commands via research-coordinator integr** - Integrate research-coordinator agent for parallel multi-topic research with 95% context reduction, e [.claude/specs/016_lean_command_coordinator_optimization/]
  - Report: [001-Lean-Plan-Analysis](.claude/specs/016_lean_command_coordinator_optimization/reports/001-lean-plan-analysis.md)
  - Report: [002-Lean-Implement-Analysis](.claude/specs/016_lean_command_coordinator_optimization/reports/002-lean-implement-analysis.md)
  - Summary: [001-Phase-1-3-Implementation-Summary](.claude/specs/016_lean_command_coordinator_optimization/summaries/001-phase-1-3-implementation-summary.md)
  - Summary: [002-Iteration-2-Complete-Implementation-Summary](.claude/specs/016_lean_command_coordinator_optimization/summaries/002-iteration-2-complete-implementation-summary.md)
- [x] **Fix /create-plan command errors from state persistence and agent validation issu** - Fix /create-plan command errors from state persistence and agent validation issues [.claude/specs/024_repair_create_plan_20251208_165703/]
  - Report: [001-Create-Plan-Errors-Repair](.claude/specs/024_repair_create_plan_20251208_165703/reports/001-create-plan-errors-repair.md)
  - Summary: [Implementation-Summary-Iteration-1](.claude/specs/024_repair_create_plan_20251208_165703/summaries/implementation-summary-iteration-1.md)
- [x] **Diagnose and fix /lean-plan command orchestrator-coordinator-specialist pattern ** - Diagnose and fix /lean-plan command orchestrator-coordinator-specialist pattern implementation gap [.claude/specs/027_lean_plan_orchestrator_debug/]
  - Report: [001-Lean-Plan-Execution-Analysis](.claude/specs/027_lean_plan_orchestrator_debug/reports/001-lean-plan-execution-analysis.md)
  - Report: [002-Orchestrator-Coordinator-Specialist-Pattern](.claude/specs/027_lean_plan_orchestrator_debug/reports/002-orchestrator-coordinator-specialist-pattern.md)
  - Report: [003-Context-Optimization-Hierarchical-Agents](.claude/specs/027_lean_plan_orchestrator_debug/reports/003-context-optimization-hierarchical-agents.md)
  - Summary: [001-Implementation-Summary](.claude/specs/027_lean_plan_orchestrator_debug/summaries/001-implementation-summary.md)
- [x] **Fix exit 127 (append_workflow_state: command not found) errors in /create-plan b** - Fix exit 127 (append_workflow_state: command not found) errors in /create-plan by adding pre-flight  [.claude/specs/032_exit_127_create_plan_fix/]
  - Report: [001-Exit-127-Error-Root-Cause](.claude/specs/032_exit_127_create_plan_fix/reports/001-exit-127-error-root-cause.md)
  - Report: [002-Create-Plan-State-Integration](.claude/specs/032_exit_127_create_plan_fix/reports/002-create-plan-state-integration.md)
  - Report: [003-Standards-Compliant-Fix-Plan](.claude/specs/032_exit_127_create_plan_fix/reports/003-standards-compliant-fix-plan.md)
  - Summary: [001-Implementation-Summary](.claude/specs/032_exit_127_create_plan_fix/summaries/001-implementation-summary.md)
- [x] **Establish standards for non-interactive testing phases in implementation plans** - Establish standards for non-interactive testing phases in implementation plans [.claude/specs/033_interactive_testing_plan_standards/]
  - Report: [001-Non-Interactive-Testing-Standards](.claude/specs/033_interactive_testing_plan_standards/reports/001-non-interactive-testing-standards.md)
  - Report: [002-Plan-Command-Analysis](.claude/specs/033_interactive_testing_plan_standards/reports/002-plan-command-analysis.md)
  - Report: [003-Documentation-Standards-Integration](.claude/specs/033_interactive_testing_plan_standards/reports/003-documentation-standards-integration.md)
  - Summary: [001-Implementation-Summary](.claude/specs/033_interactive_testing_plan_standards/summaries/001-implementation-summary.md)
  - Summary: [002-Implementation-Complete-Summary](.claude/specs/033_interactive_testing_plan_standards/summaries/002-implementation-complete-summary.md)
- [x] **Extend goose.nvim with dynamic multi-provider support for Gemini and Claude Code** - Extend goose.nvim with dynamic multi-provider support for Gemini and Claude Code [.claude/specs/039_goose_nvim_refactor_plans/]
  - Report: [001-Goose-Agent-Configuration](.claude/specs/039_goose_nvim_refactor_plans/reports/001-goose-agent-configuration.md)
  - Report: [002-Goose-Llm-Integration](.claude/specs/039_goose_nvim_refactor_plans/reports/002-goose-llm-integration.md)
  - Report: [003-Goose-Refactoring-Strategy](.claude/specs/039_goose_nvim_refactor_plans/reports/003-goose-refactoring-strategy.md)
  - Summary: [001-Goose-Nvim-Refactor-Implementation-Summary](.claude/specs/039_goose_nvim_refactor_plans/summaries/001-goose-nvim-refactor-implementation-summary.md)
- [x] **Fix state-persistence sourcing violations in repair.md and todo.md** - Fix state-persistence sourcing violations in repair.md and todo.md [.claude/specs/040_state_persistence_sourcing_fix/]
  - Report: [001-State-Persistence-Sourcing-Fix-Analysis](.claude/specs/040_state_persistence_sourcing_fix/reports/001-state-persistence-sourcing-fix-analysis.md)
- [x] **Remove unimplemented option 4 (Preview Diff Mode) from sync menu, renumber remai** - Remove unimplemented option 4 (Preview Diff Mode) from sync menu, renumber remaining options [.claude/specs/041_nvim_sync_preview_diff/]
  - Report: [001-Sync-Removal-Analysis](.claude/specs/041_nvim_sync_preview_diff/reports/001-sync-removal-analysis.md)
  - Report: [Revision 001 Remove Option 4](.claude/specs/041_nvim_sync_preview_diff/reports/revision_001_remove_option_4.md)
  - Summary: [001 Implementation Summary](.claude/specs/041_nvim_sync_preview_diff/summaries/001_implementation_summary.md)
- [x] **Update nvim documentation for Interactive mode and removal of Preview diff optio** - Update README.md documentation to add comprehensive Interactive mode section explaining the new per- [.claude/specs/042_nvim_sync_doc_updates/]
  - Report: [Research Report 042 Nvim Sync Doc Updates](.claude/specs/042_nvim_sync_doc_updates/reports/research_report_042_nvim_sync_doc_updates.md)
  - Summary: [Implementation Summary 001](.claude/specs/042_nvim_sync_doc_updates/summaries/implementation_summary_001.md)
- [x] **Fix clean copy option failing to copy artifacts due to Lua function definition o** - Single file, single module [.claude/specs/043_nvim_sync_clean_copy_fix/]
  - Report: [001-Sync-Clean-Copy-Research](.claude/specs/043_nvim_sync_clean_copy_fix/reports/001-sync-clean-copy-research.md)
  - Summary: [001-Implementation-Summary](.claude/specs/043_nvim_sync_clean_copy_fix/summaries/001-implementation-summary.md)
- [x] **Revise settings.local.json handling in claude-code sync utility - exclude from s** - Revise settings.local.json handling in claude-code sync utility - exclude from sync, add template-ba [.claude/specs/044_settings_sync_strategy/]
  - Report: [001-Settings-Sync-Strategy-Analysis](.claude/specs/044_settings_sync_strategy/reports/001-settings-sync-strategy-analysis.md)
  - Summary: [001-Settings-Sync-Strategy-Implementation-Summary](.claude/specs/044_settings_sync_strategy/summaries/001-settings-sync-strategy-implementation-summary.md)
- [x] **Unified Telescope-based picker utility for Goose recipes replacing <leader>aR ke** - Unified Telescope-based picker utility for Goose recipes replacing <leader>aR keybinding [.claude/specs/046_goose_picker_utility_recipes/]
  - Report: [001-Claude-Artifact-Picker-Research](.claude/specs/046_goose_picker_utility_recipes/reports/001-claude-artifact-picker-research.md)
  - Report: [002-Goose-Picker-Design](.claude/specs/046_goose_picker_utility_recipes/reports/002-goose-picker-design.md)
  - Report: [003-Goose-Recipes-Keybinding](.claude/specs/046_goose_picker_utility_recipes/reports/003-goose-recipes-keybinding.md)
  - Summary: [Implementation-Summary-20251209 121809](.claude/specs/046_goose_picker_utility_recipes/summaries/implementation-summary-20251209_121809.md)
- [x] **Integrate recipe picker with goose.nvim sidebar for unified output display** - Refactor recipe execution from ToggleTerm to goose.nvim sidebar UI with real-time streaming output,  [.claude/specs/049_goose_nvim_recipe_execution/]
  - Report: [001-Goose-Nvim-Architecture](.claude/specs/049_goose_nvim_recipe_execution/reports/001-goose-nvim-architecture.md)
  - Report: [002-Sidebar-Recipe-Execution](.claude/specs/049_goose_nvim_recipe_execution/reports/002-sidebar-recipe-execution.md)
  - Report: [003-Recipe-Output-Redirection](.claude/specs/049_goose_nvim_recipe_execution/reports/003-recipe-output-redirection.md)
  - Summary: [001-Implementation-Summary](.claude/specs/049_goose_nvim_recipe_execution/summaries/001-implementation-summary.md)
- [x] **Fix state machine lifecycle management in /create-plan command Block 3** - Fix state machine lifecycle management in /create-plan command Block 3 [.claude/specs/050_repair_create_plan_20251209_134800/]
  - Report: [001-Create-Plan-Errors-Repair](.claude/specs/050_repair_create_plan_20251209_134800/reports/001-create-plan-errors-repair.md)
  - Summary: [001-Implementation-Summary](.claude/specs/050_repair_create_plan_20251209_134800/summaries/001-implementation-summary.md)
- [x] **Fix bash block execution formatting corruption in /research command where newlin** - Fix bash block execution formatting corruption in /research command where newlines are removed and v [.claude/specs/989_no_name_error/]
  - Report: [001-No-Name-Error-Analysis](.claude/specs/989_no_name_error/reports/001-no-name-error-analysis.md)
  - Report: [001-Research-The-Commands-In-Claudecommand](.claude/specs/989_no_name_error/reports/001-research-the-commands-in-claudecommand.md)
  - Report: [002-Infrastructure-Integration-Analysis](.claude/specs/989_no_name_error/reports/002-infrastructure-integration-analysis.md)
  - Summary: [001-Implementation-Summary](.claude/specs/989_no_name_error/summaries/001-implementation-summary.md)
- [x] **Hybrid coordinator architecture with brief summary return pattern for context-ef** - Hybrid coordinator architecture with brief summary return pattern for context-efficient result aggre [.claude/specs/993_research_task_directive_fix/]
  - Report: [001-Research-Task-Directive-Fix-Analysis](.claude/specs/993_research_task_directive_fix/reports/001-research-task-directive-fix-analysis.md)
  - Report: [002-Infrastructure-Integration-Analysis](.claude/specs/993_research_task_directive_fix/reports/002-infrastructure-integration-analysis.md)
  - Summary: [001-Implementation-Summary-Iteration-1](.claude/specs/993_research_task_directive_fix/summaries/001-implementation-summary-iteration-1.md)
  - Summary: [002-Implementation-Summary-Iteration-2](.claude/specs/993_research_task_directive_fix/summaries/002-implementation-summary-iteration-2.md)
- [x] **Fix 7 error patterns in /research command affecting 24+ logged errors** - Fix 7 error patterns in /research command affecting 24+ logged errors [.claude/specs/997_repair_research_20251205_211418/]
  - Report: [001-Research-Errors-Repair](.claude/specs/997_repair_research_20251205_211418/reports/001-research-errors-repair.md)
  - Summary: [001-Implementation-Summary](.claude/specs/997_repair_research_20251205_211418/summaries/001-implementation-summary.md)
- [x] **Port Claude Code workflow commands to Goose ecosystem as YAML recipes** - Migrate /research, /create-plan, /revise, and /implement commands along with their dependencies (age [.claude/specs/998_goose_workflow_utilities_port/]
  - Report: [001-Goose-Workflow-Utilities-Port-Analysis](.claude/specs/998_goose_workflow_utilities_port/reports/001-goose-workflow-utilities-port-analysis.md)
  - Summary: [Implementation Summary Iteration 1](.claude/specs/998_goose_workflow_utilities_port/summaries/implementation_summary_iteration_1.md)
  - Summary: [Implementation Summary Iteration 2](.claude/specs/998_goose_workflow_utilities_port/summaries/implementation_summary_iteration_2.md)
- [x] **Convert Goose recipe primary parameters from required to user_prompt for interac** - Update 5 primary parameters across 4 main Goose recipes to enable interactive parameter prompting wh [.claude/specs/999_goose_recipes_user_prompt/]
  - Report: [001-Goose-Recipes-User-Prompt-Analysis](.claude/specs/999_goose_recipes_user_prompt/reports/001-goose-recipes-user-prompt-analysis.md)
  - Summary: [001-Implementation-Summary](.claude/specs/999_goose_recipes_user_prompt/summaries/001-implementation-summary.md)

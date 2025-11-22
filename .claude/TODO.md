# TODO

## Implementation Plans

### In Progress

- [ ] **Improve /convert-docs fidelity** - Gemini API integration for high-fidelity conversion [.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md] (Complexity: 35)
- [ ] **Refactor tests/ directory** - [/home/benjamin/.config/.claude/specs/919_test_refactor_organization/plans/001-test-refactor-organization-plan.md]

### Not Started

- **Polish Refactor** -
  - update commands readme
  - fix tests

- **Improve Outputs** -
  - [/home/benjamin/.config/.claude/build-output.md]
  - [/home/benjamin/.config/.claude/revise-output.md]
  - [/home/benjamin/.config/.claude/build-output.md]

**Medium Priority (Optimization)**:
- [ ] **Optimize commands** - Reduce duplication, consolidate bash blocks across 12 commands [.claude/specs/883_commands_optimize_refactor/plans/001_commands_optimize_refactor_plan.md] (Complexity: 142)
  - [ ] **Error logging infrastructure completion** - Helper functions + convert-docs.md error logging [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md] (4 hours)
    - Preserved valuable elements from Plan 884
    - Adds validate_required_functions() and execute_with_logging() to error-handling.sh
    - Adds error logging to convert-docs.md (completes orchestrator coverage)
- [ ] **Skills documentation standards** - Update skills authoring docs [.claude/specs/882_no_name/plans/001_skills_documentation_standards_update_plan.md]

**Lower Priority (Features)**:
- [ ] **Automatic buffer open hook** - Neovim integration for auto-opening buffers [.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md]
- [ ] **Refactor .claude/docs/** - Dependency-safe documentation restructure [.claude/specs/850_so_that_no_dependencies_break_create_a_detailed/plans/001_so_that_no_dependencies_break_create_a_d_plan.md]

### Ideas/Backlog

**Refactoring/Enhancement Ideas**:
* Refactor subagent applications throughout commands
  * [20251121_convert_docs_plan_improvements_research](specs/20251121_convert_docs_plan_improvements_research/) - Haiku subagents, orchestrator patterns, skills integration
  * Incorporate skills throughout commands
* Make /plan, /build, /revise, /debug follow appropriate standards consistently
* Make commands update TODO.md automatically
* Make metadata and summary outputs uniform across artifacts (include directory project numbers)
* make /repair update the errors that have been addressed in the logs
* change --report to --file in /repair
* /repair to check agreement with .claude/docs/ standards

**Related Research**:
- Haiku parallel subagents for /convert-docs: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md]
- Orchestrator command standards: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/002_orchestrator_command_standards.md]
- Skills integration patterns: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/003_skills_integration_patterns.md]

### Superseded

- [~] **Make /build persistent** - Superseded by Plan 899 (Build iteration infrastructure) [.claude/specs/881_build_persistent_workflow_refactor/plans/001_build_persistent_workflow_refactor_plan.md] → See [901_plan_integration_overlap_analysis](specs/901_plan_integration_overlap_analysis/reports/001_plan_integration_overlap_analysis.md)
- [~] **Unified repair implementation** - Superseded by ordered High Priority plans (1, 2, 3) which provide same coverage with better sequencing [.claude/specs/885_repair_plans_research_analysis/plans/001_repair_plans_research_analysis_plan.md] → See [repair_plans_priority_analysis](specs/repair_plans_priority_analysis/reports/001_repair_plans_priority_analysis.md)
- [~] **System-wide error logging gaps** - Phase 0 obsolete (function exists), Phase 2 duplicates Plan 2; valuable elements preserved in Plan 902 [.claude/specs/884_build_error_logging_discrepancy/plans/001_debug_strategy.md] → See [902_error_logging_infrastructure_completion](specs/902_error_logging_infrastructure_completion/reports/001_plan_884_preserved_elements.md)

### Completed

- [x] Uniform directory naming [/home/benjamin/.config/.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md]
- [x] Optimize commands [/home/benjamin/.config/.claude/specs/916_commands_docs_standards_review/plans/001_commands_docs_standards_review_plan.md]

- **Test Commands**:
- /research [/home/benjamin/.config/.claude/specs/911_research_error_analysis/plans/001_research_error_analysis_repair_plan.md]
  - output [/home/benjamin/.config/.claude/research-output.md]
  - errors [/home/benjamin/.config/.claude/specs/911_research_error_analysis/reports/001_error_report.md]

- [ ] **Test /plan command** - [/home/benjamin/.config/.claude/specs/908_plan_error_analysis/plans/001_plan_error_analysis_fix_plan.md]
  - [/home/benjamin/.config/.claude/specs/908_plan_error_analysis/reports/001_error_report.md]
  - [/home/benjamin/.config/.claude/plan-output.md]

- **Test /repairs command** - [/home/benjamin/.config/.claude/specs/915_repair_error_state_machine_fix/plans/001_repair_error_state_machine_fix_plan.md]
  - [/home/benjamin/.config/.claude/repair-output.md]
  - [/home/benjamin/.config/.claude/specs/914_repair_error_analysis/reports/001_error_report.md]

- **Test /research command** - [/home/benjamin/.config/.claude/specs/913_911_research_error_analysis_repair/plans/001_911_research_error_analysis_repair_plan.md]
  - [/home/benjamin/.config/.claude/research-output.md]
  - [/home/benjamin/.config/.claude/specs/research_error_analysis/reports/001_error_report.md]

- **Test /debug command** - [/home/benjamin/.config/.claude/specs/912_debug_error_analysis/plans/001_debug_error_analysis_repair_plan.md]
  - [/home/benjamin/.config/.claude/debug-output.md]

- **Test /build command** - [/home/benjamin/.config/.claude/specs/1039_build_errors_repair/plans/001_build_errors_repair_plan.md]
  - [/home/benjamin/.config/.claude/build-output.md]

- **Test /plan command** - [/home/benjamin/.config/.claude/specs/909_plan_command_error_repair/plans/001_plan_command_error_repair_plan.md]
  - [/home/benjamin/.config/.claude/plan-output.md]
  - [/home/benjamin/.config/.claude/specs/908_plan_error_analysis/reports/001_plan_error_report.md]
  - IMPLEMENTED [/home/benjamin/.config/.claude/specs/904_plan_command_errors_repair/plans/001_plan_command_errors_repair_plan.md]
    - [/home/benjamin/.config/.claude/specs/errors_plan_analysis/reports/001_plan_error_report.md]

- [x] **Test /errors command** - [/home/benjamin/.config/.claude/specs/907_001_error_report_repair/plans/001_001_error_report_repair_plan.md]
  - [/home/benjamin/.config/.claude/errors-output.md]
  - [/home/benjamin/.config/.claude/specs/905_error_command_directory_protocols/reports/001_error_command_directory_protocols.md]

- [x] **Test /revise command** - [/home/benjamin/.config/.claude/specs/122_revise_errors_repair/plans/001_revise_errors_repair_plan.md]
  - Console output: [/home/benjamin/.config/.claude/revise-output.md]

1. [x] **Error analysis and repair** - Fix library sourcing (exit code 127) across commands [.claude/specs/20251121_error_analysis_repair/plans/001_error_analysis_repair_plan.md] (5.5 hours) **COMPLETE**
   - Fixed foundation: three-tier sourcing pattern in /build, /errors, /plan, /revise, /research
   - All phases marked complete in plan file

2. [x] **Error logging infrastructure migration** - Enhance source-libraries-inline.sh, 100% coverage [.claude/specs/896_error_logging_infrastructure_migration/plans/001_error_logging_infrastructure_plan.md] (6 hours)
   - Depends on: Plan 1 (COMPLETE)
   - Adds error logging to expand.md, collapse.md

3. [x] **Build iteration infrastructure** - Context safety, checkpoint integration [.claude/specs/899_repair_plans_missing_elements_impl/plans/001_repair_plans_missing_elements_impl_plan.md] (17 hours)
   - Depends on: Plans 1 (COMPLETE) and 2
   - Revised 2025-11-21 to include three-tier sourcing pattern

**November 21, 2025**:
- [x] **Standards enforcement infrastructure** - Pre-commit hooks, validators, unified validation scripts [.claude/specs/111_standards_enforcement_infrastructure/plans/001_standards_enforcement_infrastructure_plan.md]
- [x] **Fix /build bash sourcing errors** - Three-tier sourcing pattern fixes for state management [.claude/specs/105_build_state_management_bash_errors_fix/plans/001_debug_strategy.md]
- [x] **Fix /plan command errors** - Parameter count bugs in validate_agent_output [.claude/specs/890_plan_command_error_debug_infrastructure/plans/001_debug_strategy.md]
- [x] **Fix /convert-docs error logging** - Error handling and logging integration [.claude/specs/889_convert_docs_error_logging_debug/plans/001_debug_strategy.md]
- [x] **Fix /debug empty directory issue** - Lazy directory creation and agent validation [.claude/specs/891_debug_command_empty_dir_infra/plans/001_debug_strategy.md]
- [x] **Fix /debug command refactor** - Block 2a library, validation logging, lazy directories [.claude/specs/894_debug_command_output_fix/plans/001_debug_command_refactor_plan.md]

**November 20, 2025**:
- [x] **Refactor /convert-docs to skills architecture** - Document-converter skill with backward compatibility [.claude/specs/879_convert_docs_skills_refactor/plans/001_skills_architecture_refactor.md]
- [x] **Update convert-docs in commands readme** - Documentation consistency [.claude/specs/882_no_name/plans/001_no_name_plan.md]
- [x] **Improve <leader>ac menu** - Neovim picker with scripts/tests artifact support [.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md]
- [x] **Clean up tests/ directory** - Test reorganization into feature subdirectories [.claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md]
- [x] **Clean up README files** - README standardization throughout .claude/ [.claude/specs/858_readmemd_files_throughout_claude_order_improve/plans/001_readmemd_files_throughout_claude_order_i_plan.md]
- [x] **Artifact console summary format** - 4-section format with emoji markers [.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md]
- [x] **Fix bash history expansion UI errors** - Bash escaping and quoting fixes [.claude/specs/876_bash_history_expansion_ui_errors_fix/plans/001_bash_history_expansion_ui_errors_fix_plan.md]
- [x] **Fix Phase 3 picker test failures** - Test environment fixes [.claude/specs/877_fix_phase3_picker_test_failures/plans/001_fix_phase3_picker_test_failures_plan.md]
- [x] **Test environment separation** - CLAUDE_TEST_MODE for isolation [.claude/specs/872_test_failure_fix_coverage/plans/001_debug_strategy.md]
- [x] **Build testing subagent phase** - Test-executor subagent for /build [.claude/specs/874_build_testing_subagent_phase/plans/001_build_testing_subagent_phase_plan.md]
- [x] **Fix lazy directory creation violations** - 6 commands with violations fixed [.claude/specs/870_fix_lazy_directory_creation_violations_across_6_co/plans/001_fix_lazy_directory_creation_violations_a_plan.md]
- [x] **Fix plan status discrepancy bug** - add_complete_marker validation [.claude/specs/867_plan_status_discrepancy_bug/plans/001_debug_strategy.md]
- [x] **Improve directory names with LLM** - Haiku subagent for topic naming [.claude/specs/866_implementation_summary_and_want/plans/001_implementation_summary_and_want_plan.md]
- [x] **Fix error logging in /build** - Error handling integration [.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md]
- [x] **Improve topic directory naming** - Infrastructure enhancement [.claude/specs/862_infrastructure_to_improve_the_names_that_will_be/plans/001_infrastructure_to_improve_the_names_that_plan.md]
- [x] **Fix ERR trap in /research** - Error trap validation [.claude/specs/863_plans_001_build_command_use_this_research_to/plans/001_plans_001_build_command_use_this_researc_plan.md]
- [x] **Command state persistence** - Bash safety remediation [.claude/specs/864_reviseoutputmd_in_order_to_identify_the_root/plans/001_reviseoutputmd_in_order_to_identify_the__plan.md]
- [x] **/errors command artifact output** - Basic output artifact creation [.claude/specs/886_errors_command_report/plans/001_errors_command_report_plan.md]

**Earlier (Nov 19-20)**:
- [x] Implement error logging in commands [.claude/specs/849_claude_planoutputmd_which_i_want_you_to_research/plans/001_claude_planoutputmd_which_i_want_you_to__plan.md]
- [x] Update docs for /errors and /repairs [.claude/specs/855_commands_readmemd_and_any_other_relevant/plans/001_commands_readmemd_and_any_other_relevant_plan.md]
- [x] Implement /setup command refactor [.claude/specs/854_001_setup_command_comprehensive_analysismd_in/plans/001_001_setup_command_comprehensive_analysis_plan.md]


# TODO

## In Progress

- [x] **Optimize /plan command performance** - Reduce execution time by 30-40% through state consolidation, bash block reduction, library sourcing optimization [.claude/specs/965_optimize_plan_command_performance/plans/001-optimize-plan-command-performance-plan.md]
  - 9 phases: Error remediation, variable initialization, state consolidation, block reduction, library guards, validation streamlining, timeout tuning, testing, documentation
- [x] **/build Errors Repair** - Fix 5% unresolved logged errors + eliminate 3 critical runtime errors bypassing error logging [.claude/specs/966_repair_build_20251129_150219/plans/001-repair-build-20251129-150219-plan.md]

## Not Started

- [ ] **Commands README update** - Update README.md to reflect current command catalog [.claude/specs/788_commands_readme_update/plans/001_commands_readme_update_plan.md]
- [ ] **Neovim buffer opening integration** - Integration for workflow commands [.claude/specs/848_when_using_claude_code_neovim_greggh_plugin/plans/001_buffer_opening_integration_plan.md]

## Backlog

**Refactoring/Enhancement Ideas**:

- check relevant standards, updating as needed
- Retry semantic directory topic names and other fail-points
- Refactor subagent applications throughout commands
  - [20251121_convert_docs_plan_improvements_research](specs/20251121_convert_docs_plan_improvements_research/) - Haiku subagents, orchestrator patterns, skills integration
  - Incorporate skills throughout commands
- Make commands update TODO.md automatically
- Make all relevant commands update TODO.md
- Make metadata and summary outputs uniform across artifacts (include directory project numbers)
- /repair to check agreement with .claude/docs/ standards
- **Command optimization and consolidation** - Consolidate fragmented commands (/expand 32->8 blocks, /collapse 29->8 blocks), standardize "Block N" documentation, evaluate initialization patterns [Merged from Plan 882]

**Related Research**:

- Haiku parallel subagents for /convert-docs: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md]
- Orchestrator command standards: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/002_orchestrator_command_standards.md]
- Skills integration patterns: [.claude/specs/20251121_convert_docs_plan_improvements_research/reports/003_skills_integration_patterns.md]

## Superseded

- [~] **Make /build persistent** - Superseded by Plan 899 (Build iteration infrastructure) [.claude/specs/881_build_persistent_workflow_refactor/plans/001_build_persistent_workflow_refactor_plan.md] → See [901_plan_integration_overlap_analysis](specs/901_plan_integration_overlap_analysis/reports/001_plan_integration_overlap_analysis.md)
- [~] **Unified repair implementation** - Superseded by ordered High Priority plans (1, 2, 3) which provide same coverage with better sequencing [.claude/specs/885_repair_plans_research_analysis/plans/001_repair_plans_research_analysis_plan.md] → See [repair_plans_priority_analysis](specs/repair_plans_priority_analysis/reports/001_repair_plans_priority_analysis.md)
- [~] **System-wide error logging gaps** - Phase 0 obsolete (function exists), Phase 2 duplicates Plan 2; valuable elements preserved in Plan 902 [.claude/specs/884_build_error_logging_discrepancy/plans/001_debug_strategy.md] → See [902_error_logging_infrastructure_completion](specs/902_error_logging_infrastructure_completion/reports/001_plan_884_preserved_elements.md)

## Abandoned

- [x] **Error logging infrastructure completion** - Helper functions (validate_required_functions, execute_with_logging) deemed unnecessary after comprehensive analysis [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md]
  - **Reason**: Error logging infrastructure already 100% complete across all 12 commands
  - **Analysis**: setup_bash_error_trap already catches function-not-found errors; helper functions would trade context-specific error messages for generic ones (net negative)
  - **Alternative**: Focus on Plan 883 (Commands Optimize Refactor) for measurable improvements
  - See [Infrastructure Optimization Analysis](specs/949_commands_infrastructure_research/reports/001_infrastructure_optimization_analysis.md)

- [x] **/revise errors repair (122)** - Verify and close out existing repair work [.claude/specs/122_revise_errors_repair/plans/001-revise_errors_repair-plan.md]
  - **Reason**: Superseded by multiple completed repair plans (876, 864, 955)
  - All /revise command errors have been fixed: history expansion (set +H in all commands), library sourcing (three-tier pattern), state machine (sm_validate_state exists)

- [x] **Coordinate command archival (799)** - Archive /coordinate command with all dependencies [.claude/specs/799_coordinate_command_all_its_dependencies_order/plans/001_coordinate_command_all_its_dependencies__plan.md]
  - **Reason**: Work already completed - coordinate.md no longer exists (already archived)
  - Command references already cleaned up by Plan 801

- [x] **Plan status metadata (805)** - Add plan-level status field to metadata section [.claude/specs/805_when_plans_created_command_want_metadata_include/plans/001_when_plans_created_command_want_metadata_plan.md]
  - **Reason**: Plan phases marked [COMPLETE] but Status metadata stale
  - Work was completed: plan-architect now includes Status field in template

- [x] **README.md revision (806)** - Revise specific sections of commands/README.md [.claude/specs/806_claude_commands_readmemd_revise_adaptive_plan/plans/001_claude_commands_readmemd_revise_adaptive_plan.md]
  - **Reason**: All 4 phases marked [COMPLETE] but Status metadata stale
  - Work was completed: Adaptive Plan Structures, Standards Discovery, inline examples all updated

- [x] **Fix /revise command errors (822)** - Bash history expansion, CLAUDE_PROJECT_DIR bootstrap [.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md]
  - **Reason**: Fixed by Plan 876 (Fix bash history expansion UI errors)
  - All commands now have `set +H` (verified via grep), three-tier sourcing pattern applied

- [x] **Empty debug directory creation bug (869)** - Update 6 commands to enforce lazy directory creation [.claude/specs/869_debug_directory_creation_bug/plans/001_debug_strategy.md]
  - **Reason**: Fixed by Plan 870 (Fix lazy directory creation violations across 6 commands)
  - Same scope and objective - Plan 870 was the implementation

- [x] **/plan command errors repair alternate (904)** - Error handling and library sourcing [.claude/specs/904_plan_command_errors_repair/plans/001-plan-command-errors-repair-plan.md]
  - **Reason**: Superseded by completed Plans 908, 909 which fixed /plan command errors
  - Note: There is a completed Plan 904 in the Completed section - this is a different plan file (001_plan_command_errors_repair_plan.md vs 001-plan-command-errors-repair-plan.md)

- [x] **/errors command directory protocols (906)** - Single command file with library integration [.claude/specs/906_errors_command_directory_protocols/plans/001_errors_command_directory_protocols_plan.md]
  - **Reason**: Work already completed - /errors now sources workflow-initialization.sh and uses initialize_workflow_paths()
  - Verified: grep confirms workflow-initialization.sh sourced at lines 274, 371

- [x] **Directory numbering bug debug (910)** - Fix topic-utils.sh numbering [.claude/specs/910_repair_directory_numbering_bug/plans/001_debug_strategy.md]
  - **Reason**: Fixed by Plan 946 (Fix spec directory numbering collision)
  - Atomic allocation via allocate_and_create_topic() now eliminates race conditions and 4-digit anomalies

- [x] **/debug command library sourcing fix (912)** - Library sourcing repair [.claude/specs/912_debug_error_analysis/plans/001_debug_error_analysis_repair_plan.md]
  - **Reason**: Plan phases marked with [x] (complete) but Status metadata stale
  - Work was completed: workflow-initialization.sh sourcing added to /debug Part 3

- [x] **Repair error state machine fix (915)** - State machine repair [.claude/specs/915_repair_error_state_machine_fix/plans/001_repair_error_state_machine_fix_plan.md]
  - **Reason**: Work already implemented - sm_validate_state() exists in workflow-state-machine.sh (lines 740-767)
  - State persistence and validation patterns now standard across all commands

- [x] **/research command error repair (921)** - State machine initialization and validation [.claude/specs/921_no_name_error/plans/001-research-command-error-repair-plan.md]
  - **Reason**: Superseded by completed Plans 925 (repair research plan refactor), 955 (error capture trap timing)
  - State machine guards, benign error filtering, and trap timing all addressed

- [x] **/research command error repair patterns (935)** - Topic naming and bash environment [.claude/specs/935_errors_repair_research/plans/001-errors-repair-research-plan.md]
  - **Reason**: Superseded by completed Plans 925, 955, 911, 913
  - Topic naming, bash environment, state machine issues all fixed in completed plans

- [x] **/plan errors repair (939)** - Agent failures and library sourcing [.claude/specs/939_errors_repair_plan/plans/001-errors-repair-plan-plan.md]
  - **Reason**: Many overlapping concerns already fixed by Plans 908, 909, 955
  - Critical state file mismatch finding is valid but should be addressed in a new focused plan if still occurring

- [x] **Command protocols disposition (830)** - Review and integrate command protocols [.claude/specs/830_specs_standards_commandprotocolsmd_was_created/plans/001_command_protocols_disposition_plan.md]
  - **Reason**: Decision plan recommending deletion - command-protocols.md represents over-engineering
  - Current state-based orchestration architecture already provides coordination (67% faster, 95.6% context reduction)

- [x] **Error analysis and repair (841)** - Implement 4 recommendations from error analysis [.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md]
  - **Reason**: Superseded by completed Plans 955, 956, 959
  - All 4 objectives addressed: error segregation, cleanup utility, log rotation, enhanced metadata

- [x] **Build phase progress metadata (857)** - Display current phase number in plan metadata [.claude/specs/857_command_order_make_update_metadata_specify_phase/plans/001_build_phase_progress_metadata_plan.md]
  - **Reason**: Low value (cosmetic) relative to high implementation effort (6 hours, complexity 32)
  - Phase progress already visible through heading markers in plan files

- [x] **Error analysis comprehensive (871)** - Infrastructure failures and build workflow issues [.claude/specs/871_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md]
  - **Reason**: 40-60% overlap with completed Plans 955, 956, 959, 787
  - Core objectives (error capture, state persistence, preprocessing safety) already achieved

## Completed

**November 29, 2025**:

- [x] **Fix /repair command spec numbering** - Implement timestamp-based topic naming for unique spec directories [.claude/specs/961_repair_spec_numbering_allocation/plans/001-repair-spec-numbering-allocation-plan.md]
  - 4 phases complete: Direct timestamp naming replaces LLM-based naming (eliminates 2-3s latency + API cost)
- [x] **Fix 4 failing test compliance issues** - Error logging, if negation patterns, empty directories, executable/doc separation [.claude/specs/962_fix_failing_tests_compliance/plans/001-fix-failing-tests-compliance-plan.md]
  - 6 phases complete: /todo log_command_error(), collapse.md exit code patterns, empty directory removal, size violations
- [x] **README compliance audit updates** - Update 58 READMEs for Purpose/Navigation section compliance [.claude/specs/958_readme_compliance_audit_updates/plans/001-readme-compliance-audit-updates-plan.md]
  - All 9 phases complete: library subdirectories, top-level directories, validation
- [x] **/todo command and project tracking** - Create /todo command with Haiku analysis [.claude/specs/959_todo_command_project_tracking_standards/plans/001-todo-command-project-tracking-standards-plan.md]
  - All 8 phases complete: command, agent, library, standards, CLAUDE.md integration
- [x] **README compliance full implementation** - Fix validator script and create missing READMEs [.claude/specs/960_readme_compliance_audit_implement/plans/001-readme-compliance-audit-implement-plan.md]
  - All 9 phases complete: 100% compliance achieved (88/88 READMEs)
- [x] **Error log status tracking** - Add RESOLVED status to error lifecycle [.claude/specs/956_error_log_status_tracking/plans/001-error-log-status-tracking-plan.md]
  - All 2 phases complete
- [x] **Hard barrier subagent delegation compliance** - Documentation and validation [.claude/specs/957_revise_subagent_delegation_fix/plans/001-revise-subagent-delegation-fix-plan.md]
  - All 8 phases complete
- [x] **State machine persistence bug fix (787)** - Fix STATE_FILE persistence across bash subprocess boundaries [.claude/specs/787_state_machine_persistence_bug/plans/001_state_machine_persistence_fix_plan.md]
  - Evidence: lib/core/state-persistence.sh exists with load_workflow_state(), append_workflow_state(), atomic operations
- [x] **Guides directory refactor (807)** - Archive unused files and create subdirectory organization [.claude/specs/807_docs_guides_directory_has_become_bloated/plans/001_docs_guides_directory_has_become_bloated_plan.md]
  - Evidence: guides/ has commands/, development/, orchestration/, patterns/, templates/ subdirectories
- [x] **Reference directory refactoring (814)** - Reorganize 40 files into logical subdirectories [.claude/specs/814_docs_references_directory_has_become_bloated/plans/001_docs_references_directory_has_become_blo_plan.md]
  - Evidence: reference/ has architecture/, workflows/, library-api/, standards/, templates/, decision-trees/ subdirectories
- [x] **Markdown-link-check config relocation (817)** - Move configuration file and update references [.claude/specs/817_claude_scripts_readmemd_research_and_plan_these/plans/001_claude_scripts_readmemd_research_and_pla_plan.md]
  - Evidence: Plan metadata shows [COMPLETE] in all 3 phases
- [x] **Remaining broken references fix (818)** - Update 8 broken references across 3 files [.claude/specs/818_816_807_docs_guides_directory_has_become_bloated/plans/001_816_807_docs_guides_directory_has_become_plan.md]
  - Evidence: Plan metadata shows [COMPLETE], superseded by 807/814 completion
- [x] **Library directory refactor (820)** - Archive unused libraries and organize into subdirectories [.claude/specs/820_archive_and_backups_directories_can_be_safely/plans/001_archive_and_backups_directories_can_be_s_plan.md]
  - Evidence: lib/ has core/, workflow/, plan/, artifact/, convert/, util/ subdirectories
- [x] **Fix broken references after reference directory refactoring (821)** - Update 23 broken references [.claude/specs/821_814_docs_references_directory_has_become_bloated/plans/001_814_docs_references_directory_has_become_plan.md]
  - Evidence: Plan metadata shows [COMPLETE] in all 4 phases
- [x] **Quick reference integration (822)** - Reorganize quick-reference/ into reference/decision-trees/ [.claude/specs/822_quick_reference_integration/plans/001_quick_reference_integration_plan.md]
  - Evidence: reference/decision-trees/ exists with 6 flowchart files

**November 27-28, 2025**:

- [x] **Orchestrator subagent delegation** - Comprehensive fix for 13 commands to enforce subagent delegation [.claude/specs/950_revise_refactor_subagent_delegation/plans/001-revise-refactor-subagent-delegation-plan.md]
  - All 26 phases complete: /revise, /build, /expand, /collapse, /errors, /research, /debug, /repair fixed
  - Created reusable hard barrier pattern documentation and barrier-utils.sh library
  - 40-60% context reduction achieved through proper delegation
- [x] **Fix failing tests** - Remediate 26 failing tests to achieve 100% pass rate [.claude/specs/952_fix_failing_tests_coverage/plans/001-fix-failing-tests-coverage-plan.md]
  - All 8 phases complete: path resolution, bash syntax, standards compliance, test implementations, infrastructure fixes
  - Pass rate improved from 77% (87/113) to ~100%
- [x] **README docs standards audit** - Systematic README.md audit and creation [.claude/specs/953_readme_docs_standards_audit/plans/001-readme-docs-standards-audit-plan.md]
  - All 8 phases complete: temporal markers removed, READMEs created for fixtures, guides, skills, scripts, tests
  - Created 35+ new READMEs following documentation standards
- [x] **Fix failing test suites** - Infrastructure issues and code bugs [.claude/specs/953_readme_docs_standards_audit/plans/001-fix-failing-test-suites-plan.md]
  - All 8 phases complete
- [x] **Completion signals echo output** - Add completion signal echo to workflow commands [.claude/specs/954_completion_signals_echo_output/plans/001-completion-signals-echo-output-plan.md]
  - All phases complete: buffer-opener pane targeting fixed, signals added to /plan, /research, /build, /debug, /repair, /errors
  - Enables automatic buffer opening via post-buffer-opener hook
- [x] **Error capture trap timing** - Fix timing gaps where errors escape logging [.claude/specs/955_error_capture_trap_timing/plans/001-error-capture-trap-timing-plan.md]
  - All 7 phases complete: pre-trap buffering, defensive traps, benign filtering, sourcing diagnostics, workflow ID validation
  - Applied fixes to all 7 commands (/plan, /build, /debug, /research, /revise, /errors, /repair)

**November 26, 2025**:

- [x] **Documentation cleanup** - Remove legacy content, fix broken links, establish archive policy [.claude/specs/850_so_that_no_dependencies_break_create_a_detailed/plans/001_so_that_no_dependencies_break_create_a_d_plan.md]
  - All 3 phases complete: legacy content removal, broken link fixes, archive policy documentation
  - Removed ~3,926 lines of duplicate legacy content from index files
- [x] **Commands optimize refactor** - Reduce duplication, consolidate bash blocks, standardize terminology [.claude/specs/883_commands_optimize_refactor/plans/001_commands_optimize_refactor_plan.md]
  - All 5 phases complete: library consolidation, block consolidation analysis, documentation standardization, testing/validation, library adoption
  - Created `workflow-bootstrap.sh` with `bootstrap_workflow_env()` and `load_tier1_libraries()` functions
- [x] **/build errors repair** - Fix remaining build command errors [.claude/specs/934_build_errors_repair/plans/001-build-errors-repair-plan.md]
  - All 5 phases complete: library sourcing, state transitions, defensive patterns, validation
  - Resolved 12 errors (6 function calls, 3 transitions, 2 parsing, 1 benign)
- [x] **/debug errors repair** - Fix debug command errors [.claude/specs/941_debug_errors_repair/plans/001-debug-errors-repair-plan.md]
  - All 4 phases complete: library audit, state transitions, benign filter, validation
- [x] **Load All Artifacts completeness** - Fix recursive scanning to copy 100% of artifacts [.claude/specs/948_load_artifacts_completeness_refactor/plans/001-load-artifacts-completeness-refactor-plan.md]
  - All 5 phases complete: recursive scanning foundation, skills directory support, dynamic directory creation

**November 23-24, 2025**:

- [x] **Idempotent state transitions** - Same-state transition handling for retry/resume scenarios [.claude/specs/947_idempotent_state_transitions/plans/001-idempotent-state-transitions-plan.md]
  - All phases complete: state machine implementation, documentation, test coverage, validation
- [x] **Fix spec directory numbering collision** - Path canonicalization fix [.claude/specs/946_errors_spec_numbering_fix/plans/001-errors-spec-numbering-fix-plan.md]
  - All 5 phases complete: canonicalization, allocation enhancement, collision logging
- [x] **Fix /repair command state machine** - State transition sequence and validation [.claude/specs/943_errors_repair/plans/001-errors-repair-plan.md]
  - All 5 issues fixed
- [x] **Error logging coverage refactor** - Comprehensive error logging across all commands [.claude/specs/945_errors_logging_refactor/plans/001-errors-logging-refactor-plan.md]
  - Phases 1-5 complete
- [x] **Fix /errors directory numbering** - Fixed project directory numbering [.claude/specs/933_error_numbering_increment_fix/plans/001-error-numbering-increment-fix-plan.md]
- [x] **Fix /repair --file flag** - Error logging file flag support [.claude/specs/930_error_logging_file_flag_repair/plans/001-error-logging-file-flag-repair-plan.md]
- [x] **Debug test coverage quality** - Improved debug strategy [.claude/specs/929_debug_test_coverage_quality/plans/001-debug-strategy.md]
- [x] **Clean-break refactor standard** - Documentation standard [.claude/specs/928_clean_break_refactor_standard/plans/001-clean-break-refactor-standard-plan.md]
- [x] **/build metadata refactor** - Workflow metadata updates [.claude/specs/927_build_workflow_metadata_refactor/plans/001-build-workflow-metadata-refactor-plan.md]
- [x] **Fix /research command** - Repair research plan refactor [.claude/specs/925_repair_research_plan_refactor/plans/001-repair-research-plan-refactor-plan.md]
- [x] **Refactor /repair command** - Error status refactor with --file flag [.claude/specs/924_repair_error_status_refactor/plans/001-repair-error-status-refactor-plan.md]
- [x] **Refactor /convert-docs** - Subagent converter skill strategy [.claude/specs/923_subagent_converter_skill_strategy/plans/001-subagent-converter-refactor-plan.md]
- [x] **Tests directory refactor** - Test organization [.claude/specs/919_test_refactor_organization/plans/001-test-refactor-organization-plan.md]

**November 22, 2025**:

- [x] **Uniform directory naming** - Topic naming standards kebab-case [.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md]
- [x] **Optimize commands** - Commands docs standards review [.claude/specs/916_commands_docs_standards_review/plans/001_commands_docs_standards_review_plan.md]
- [x] **Improve /convert-docs fidelity** - Gemini API integration [.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md]
- [x] **Skills documentation update** - Update commands/README.md, create skills standards [.claude/specs/882_no_name/plans/001_skills_documentation_standards_update_plan.md]
- [x] **/convert-docs skills architecture refactor** - Document-converter skill [.claude/specs/879_convert_docs_skills_refactor/plans/001_skills_architecture_refactor.md]
- [x] **/research command error repair** - Fix 3 identified error patterns [.claude/specs/911_research_error_analysis/plans/001_research_error_analysis_repair_plan.md]
- [x] **/research command error analysis repair** - Library sourcing and validation [.claude/specs/913_911_research_error_analysis_repair/plans/001_911_research_error_analysis_repair_plan.md]
- [x] **/errors command directory protocol compliance** - Directory creation and workflow [.claude/specs/907_001_error_report_repair/plans/001_001_error_report_repair_plan.md]
- [x] **/plan command error fixes** - Error handling improvements and LLM validation [.claude/specs/908_plan_error_analysis/plans/001_plan_error_analysis_fix_plan.md]
- [x] **/plan command error repair** - Infrastructure and agent validation [.claude/specs/909_plan_command_error_repair/plans/001_plan_command_error_repair_plan.md]
- [x] **/plan command errors repair** - Fix exit code 127 bash sourcing [.claude/specs/904_plan_command_errors_repair/plans/001_plan_command_errors_repair_plan.md]

**November 21, 2025**:

- [x] **Standards enforcement infrastructure** - Pre-commit hooks, validators, unified validation scripts [.claude/specs/111_standards_enforcement_infrastructure/plans/001_standards_enforcement_infrastructure_plan.md]
- [x] **Fix /build bash sourcing errors** - Three-tier sourcing pattern fixes for state management [.claude/specs/105_build_state_management_bash_errors_fix/plans/001_debug_strategy.md]
- [x] **Fix /plan command errors** - Parameter count bugs in validate_agent_output [.claude/specs/890_plan_command_error_debug_infrastructure/plans/001_debug_strategy.md]
- [x] **Fix /convert-docs error logging** - Error handling and logging integration [.claude/specs/889_convert_docs_error_logging_debug/plans/001_debug_strategy.md]
- [x] **Fix /debug empty directory issue** - Lazy directory creation and agent validation [.claude/specs/891_debug_command_empty_dir_infra/plans/001_debug_strategy.md]
- [x] **Fix /debug command refactor** - Block 2a library, validation logging [.claude/specs/894_debug_command_output_fix/plans/001_debug_command_refactor_plan.md]
- [x] **Error logging infrastructure migration** - Enhance source-libraries-inline.sh [.claude/specs/896_error_logging_infrastructure_migration/plans/001_error_logging_infrastructure_plan.md]
- [x] **Build iteration infrastructure** - Context safety and checkpoint integration [.claude/specs/899_repair_plans_missing_elements_impl/plans/001_repair_plans_missing_elements_impl_plan.md]

**November 20, 2025**:

- [x] **Build testing subagent phase** - Test-executor subagent for /build [.claude/specs/874_build_testing_subagent_phase/plans/001_build_testing_subagent_phase_plan.md]
- [x] **Fix bash history expansion UI errors** - Bash escaping and quoting fixes [.claude/specs/876_bash_history_expansion_ui_errors_fix/plans/001_bash_history_expansion_ui_errors_fix_plan.md]
- [x] **Fix Phase 3 picker test failures** - Test environment fixes [.claude/specs/877_fix_phase3_picker_test_failures/plans/001_fix_phase3_picker_test_failures_plan.md]
- [x] **Test environment separation** - CLAUDE_TEST_MODE for isolation [.claude/specs/872_test_failure_fix_coverage/plans/001_debug_strategy.md]
- [x] **Fix lazy directory creation violations** - 6 commands with violations fixed [.claude/specs/870_fix_lazy_directory_creation_violations_across_6_co/plans/001_fix_lazy_directory_creation_violations_a_plan.md]
- [x] **Fix plan status discrepancy bug** - add_complete_marker validation [.claude/specs/867_plan_status_discrepancy_bug/plans/001_debug_strategy.md]
- [x] **Improve directory names with LLM** - Haiku subagent for topic naming [.claude/specs/866_implementation_summary_and_want/plans/001_implementation_summary_and_want_plan.md]
- [x] **Fix error logging in /build** - Error handling integration [.claude/specs/861_build_command_use_this_research_to_create_a/plans/001_build_command_use_this_research_to_creat_plan.md]
- [x] **Command state persistence** - Bash safety remediation [.claude/specs/864_reviseoutputmd_in_order_to_identify_the_root/plans/001_reviseoutputmd_in_order_to_identify_the__plan.md]
- [x] **/errors command artifact output** - Basic output artifact creation [.claude/specs/886_errors_command_report/plans/001_errors_command_report_plan.md]
- [x] **Artifact console summary format** - 4-section format with emoji markers [.claude/specs/878_artifact_console_summary_format/plans/001_artifact_console_summary_format_plan.md]
- [x] **Improve topic directory naming** - Infrastructure enhancement [.claude/specs/862_infrastructure_to_improve_the_names_that_will_be/plans/001_infrastructure_to_improve_the_names_that_plan.md]
- [x] **Fix ERR trap in /research** - Error trap validation [.claude/specs/863_plans_001_build_command_use_this_research_to/plans/001_plans_001_build_command_use_this_researc_plan.md]
- [x] **Test directory reorganization** - Reorganize tests from flat to hierarchical [.claude/specs/868_directory_has_become_bloated/plans/001_directory_has_become_bloated_plan.md]
- [x] **Topic naming standards kebab-case** - Add topic-naming-agent to commands [.claude/specs/918_topic_naming_standards_kebab_case/plans/001_topic_naming_standards_kebab_case_plan.md]
- [x] **Hook-based buffer opening** - Claude Code hooks + Neovim integration [.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md]
- [x] **/setup command refactoring** - Mode consolidation and command separation [.claude/specs/854_001_setup_command_comprehensive_analysismd_in/plans/001_001_setup_command_comprehensive_analysis_plan.md]

**Earlier (Nov 15-19)**:

- [x] **Library path fixes** - Comprehensive fix of incorrect library paths [.claude/specs/824_claude_planoutputmd_in_order_to_create_a_plan_to/plans/001_claude_planoutputmd_in_order_to_create_a_plan.md]
- [x] **Error logging system** - Full-stack error logging infrastructure [.claude/specs/827_when_run_commands_such_on_want_able_log_all/plans/001_when_run_commands_such_on_want_able_log__plan.md]
- [x] **Remaining failing tests fix** - Bug fixes and test path repair [.claude/specs/829_826_refactoring_claude_including_libraries_this/plans/001_826_refactoring_claude_including_librari_plan.md]
- [x] **/repair command implementation** - New orchestrator command [.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/plans/001_plan_command_except_that_what_it_does_is_plan.md]
- [x] **Unused scripts cleanup** - .claude/scripts/ cleanup [.claude/specs/833_claude_scripts_directory_to_identify_if_any/plans/001_claude_scripts_directory_to_identify_if_plan.md]
- [x] **Fix remaining failing tests** - Bug fixes in error-handling.sh [.claude/specs/834_fix_remaining_failing_tests_test_command/plans/001_fix_remaining_failing_tests_test_comman_plan.md]
- [x] **/errors command standards compliance** - Documentation infrastructure [.claude/specs/835_standards_and_adequately_documented_in_claude/plans/001_standards_and_adequately_documented_in_c_plan.md]
- [x] **Build command summary link requirements** - Update template validation [.claude/specs/836_build_command_creating_a_plan_to_require_the/plans/001_build_command_creating_a_plan_to_require_plan.md]
- [x] **Commands README.md update** - Add /repair and /errors [.claude/specs/838_commands_readmemd_given_the_creation_of_the_new/plans/001_commands_readmemd_given_the_creation_of__plan.md]
- [x] **Systematic fix for state validation** - Error logging across workflow commands [.claude/specs/849_claude_planoutputmd_which_i_want_you_to_research/plans/001_claude_planoutputmd_which_i_want_you_to__plan.md]
- [x] **/setup and /optimize-claude modernization** - Full standards compliance [.claude/specs/846_001_error_analysis_repair_plan_20251119_232415md/plans/001_001_error_analysis_repair_plan_20251119__plan.md]
- [x] **Error logging standards update** - Automatic log separation [.claude/specs/847_updating_the_standard_for_error_logging_to_claude/plans/001_updating_the_standard_for_error_logging__plan.md]
- [x] **Build command phase update** - Phase completion updates [.claude/specs/789_docs_standards_in_order_to_create_a_plan_to_fix/plans/001_docs_standards_in_order_to_create_a_plan_plan.md]
- [x] **State machine transition error fix** - Build command state transitions [.claude/specs/790_fix_state_machine_transition_error_build_command/plans/001_fix_state_machine_transition_error_build_plan.md]
- [x] **--file option for long prompts** - Add flag to /plan, /research, /debug [.claude/specs/793_reports_001_long_prompt_handling_analysismd_in/plans/001_reports_001_long_prompt_handling_analysi_plan.md]
- [x] **Documentation standards update** - 8 files plus new reference document [.claude/specs/794_001_comprehensive_output_formatting_refactormd_to/plans/001_001_comprehensive_output_formatting_refa_plan.md]
- [x] **Commands README.md documentation update** - Revise 11 command entries [.claude/specs/795_claude_commands_readmemd_accordingly_all_flags/plans/001_claude_commands_readmemd_accordingly_all_plan.md]
- [x] **Agents README.md update** - Add command mappings and dependencies [.claude/specs/797_claude_agents_readmemd_specifying_where_each/plans/001_claude_agents_readmemd_specifying_where__plan.md]
- [x] **/revise command flag additions** - Flag parsing and execution gate [.claude/specs/798_reports_001_flag_analysis_simplificationmd_to/plans/001_reports_001_flag_analysis_simplification_plan.md]
- [x] **Archive documentation-only agents** - Archive 8 agents and clean references [.claude/specs/800_claude_agents_readmemd_to_help_identify_these/plans/001_claude_agents_readmemd_to_help_identify__plan.md]
- [x] **Coordinate command references cleanup** - Remove archived command references [.claude/specs/801_claude_commands_readmemd_and_likely_elsewhere/plans/001_claude_commands_readmemd_and_likely_else_plan.md]
- [x] **Fix workflow ID mismatch** - State persistence and ID propagation [.claude/specs/802_fix_workflow_mismatch_command_where_workflow_id/plans/001_fix_workflow_mismatch_command_where_work_plan.md]
- [x] **Remove Next Steps section** - Build command Block 4 output cleanup [.claude/specs/803_claude_buildoutputmd_which_looks_ok_but_i_dont/plans/001_claude_buildoutputmd_which_looks_ok_but__plan.md]
- [x] **Commands README restructure** - Reorganize sections and enhance architecture [.claude/specs/804_build_commands_included_there_then_move/plans/001_build_commands_included_there_then_move_plan.md]
- [x] **/revise command error repair** - Add workflow-state-machine.sh sourcing [.claude/specs/122_revise_errors_repair/plans/001_revise_errors_repair_plan.md]
- [x] **README improvement and documentation audit** - Comprehensive README audit [.claude/specs/858_readmemd_files_throughout_claude_order_improve/plans/001_readmemd_files_throughout_claude_order_i_plan.md]
- [x] **Build metadata status update** - Add status update functions [.claude/specs/820_build_command_metadata_status_update/plans/001_build_metadata_status_update_plan.md]
- [x] **Basic usage guide** - Document workflows and pipelines [.claude/specs/819_revise_expand_build_add_basic_usage_guide/plans/001_revise_expand_build_add_basic_usage_guid_plan.md]
- [x] **Broken cross-references fix** - Update ~150 broken links [.claude/specs/816_807_docs_guides_directory_has_become_bloated/plans/001_807_docs_guides_directory_has_become_blo_plan.md]
- [x] **Empty directory prevention** - Test isolation and workflow init [.claude/specs/815_infrastructure_to_identify_potential_causes_and/plans/001_infrastructure_to_identify_potential_cau_plan.md]
- [x] **Documentation updates for error logging** - Update Commands README and pattern docs [.claude/specs/855_commands_readmemd_and_any_other_relevant/plans/001_commands_readmemd_and_any_other_relevant_plan.md]
- [x] **Broken links fix after quick reference integration** - Update 102+ broken link references [.claude/specs/823_broken_links_after_quick_reference_integration/plans/001_broken_links_fix_plan.md]
- [x] **Dead links fix after lib reorganization** - Fix all broken links from lib/ directory changes [.claude/specs/825_summaries_001_implementation_summarymd_to/plans/001_dead_links_fix_plan.md]
- [x] **Fix failing tests after library refactoring** - Update test file paths and assertions [.claude/specs/826_refactoring_claude_including_libraries_this/plans/001_refactoring_claude_including_libraries_t_plan.md]
- [x] **Error logging documentation integration** - Integrate error logging docs into .claude/docs/ [.claude/specs/840_infrastructure_and_want_to_make_sure_that_its/plans/001_infrastructure_and_want_to_make_sure_tha_plan.md]
- [x] **Remove redundant doc-converter-usage.md** - Delete redundant documentation file [.claude/specs/844_docconverterusagemd_if_anything_and_can_this_file/plans/001_docconverterusagemd_if_anything_and_can__plan.md]

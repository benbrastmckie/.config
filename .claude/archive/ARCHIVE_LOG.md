# Archive Log

## 2025-01-15: Agents and Library Scripts (Topic 722)

**Archived Items**: 8 total (3 agents, 5 library scripts)

**Rationale**: Following command archival (Topic 721), these items no longer have active dependencies.

**Research**: See Topic 722 research reports

**Agents Archived**:
- code-reviewer.md (used by archived test.md)
- test-specialist.md (used by archived test-all.md)
- doc-writer.md (used by archived document.md)

**Library Scripts Archived**:
- analyze-metrics.sh (used by archived analyze.md)
- checkpoint-580.sh (legacy, superseded by checkpoint-utils.sh)
- workflow-detection.sh.backup-before-task2.2 (backup file)
- workflow-scope-detection.sh.backup-phase1 (backup file)
- workflow-state-machine.sh.backup (backup file)

## 2025-01-15: Tests for Deleted/Archived Commands (Topic 722 Extension)

**Archived Items**: 14 total (8 orchestrate tests, 4 supervise tests, 2 library tests)

**Rationale**: Following deletion of orchestrate.md and supervise.md (Topic 718) and archival of agents/libraries (Topic 722), these tests no longer have valid targets.

**Research**: See Topic 722 debug/002_test_archival_analysis.md

**Orchestrate Tests Archived** (8):
- benchmark_orchestrate.sh
- e2e_orchestrate_full_workflow.sh
- test_orchestrate_integrated_fix.sh
- test_orchestrate_planning_behavioral_injection.sh
- test_orchestrate_refactor.sh
- test_orchestrate_research_enhancements.sh
- test_orchestrate_research_enhancements_simple.sh
- validate_orchestrate_pattern.sh

**Supervise Tests Archived** (4):
- test_supervise_agent_delegation.sh
- test_supervise_brief_summary.sh
- test_supervise_delegation.sh
- test_supervise_scope_detection.sh

**Library Tests Archived** (2):
- analyze_test_results.sh (tested archived analyze-metrics.sh)
- test_agent_metrics.sh (sourced archived analyze-metrics.sh)

**Meta-Tests Updated** (2):
- test_all_fixes_integration.sh (removed orchestrate test references)
- test_orchestration_commands.sh (removed supervise test references)

**Impact**:
- Tests before: 126
- Tests archived: 14
- Tests remaining: 112 (11% reduction)

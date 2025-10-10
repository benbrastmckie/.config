# Claude Code System Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-09
- **Feature**: Comprehensive .claude/ System Optimization
- **Scope**: Template expansion, metrics aggregation, command optimization, documentation extraction, workflow improvements
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: .claude/OPTIMIZE.md (analysis document)
- **Complexity**: High

## Overview

This plan implements systematic optimizations to the Claude Code .claude/ system based on comprehensive analysis in OPTIMIZE.md. The optimization focuses on six high-impact areas that will deliver measurable improvements in usability, maintainability, and efficiency.

### Target Outcomes
- **Time Savings**: 15-20 hours/month through enhanced templates and automation
- **Code Reduction**: 30% LOC reduction in command files (8,700 → ~6,200 lines)
- **User Experience**: 40% faster onboarding through better documentation and guidance
- **Maintainability**: Clearer command responsibilities and shared documentation patterns

### Current State
- 20 commands (8,700+ LOC) with significant documentation bloat
- 4 templates covering only 20% of command types
- Manual metrics analysis via `jq` queries
- No complexity pre-analysis before plan creation
- Command overlap between `/revise`, `/update`, `/expand`
- Limited agent performance tracking

## Success Criteria
- [ ] Template coverage increased from 20% to 75% (6 new templates created)
- [ ] Metrics aggregation system operational with automated analysis
- [ ] `/plan` command includes complexity pre-analysis recommendations
- [ ] Command documentation reduced by 1,500-2,000 LOC via extraction
- [ ] `/update` command deprecated with clear migration path
- [ ] `/analyze agents` provides detailed performance metrics
- [ ] All tests passing (93/93 baseline maintained)
- [ ] Documentation updated to reflect all changes

## Technical Design

### Architecture Decisions

1. **Template Library Expansion**
   - Location: `.claude/templates/`
   - Format: YAML with metadata (category, complexity_level, estimated_time)
   - Categories: debug-workflow, documentation-update, test-suite, migration, research-report, refactor-consolidation
   - Integration: Enhanced `/plan-from-template` with category filtering

2. **Metrics Aggregation System**
   - New utility: `.claude/lib/analyze-metrics.sh` (~300 lines)
   - New command: `.claude/commands/analyze-metrics.md` (~150 lines)
   - Data source: `.claude/data/metrics/agents/*.jsonl`, command metrics
   - Output: Markdown reports in `specs/reports/`
   - Integration: Add subcommand to existing `/analyze` command

3. **Complexity Pre-Analysis**
   - Integration point: `/plan` command before plan generation
   - Utility: `complexity-utils.sh` new function `analyze_feature_description()`
   - Recommendations: Starting structure, phase count, template suggestions
   - User control: `--skip-analysis` flag for manual control

4. **Documentation Extraction**
   - New file: `.claude/docs/command-patterns.md` (~800 lines)
   - Extracted patterns: Agent invocation, checkpoint management, error recovery, artifact referencing
   - Update strategy: Replace inline examples with references in all 20 commands
   - Priority targets: `/orchestrate` (2,476→1,500), `/setup` (2,230→1,400), `/implement` (1,553→1,000)

5. **Command Consolidation**
   - Keep: `/revise` (interactive content changes), `/expand`+`/collapse` (structural changes)
   - Deprecate: `/update` (absorbed by `/revise`)
   - Migration: Add deprecation warning, update documentation, expand `/revise` capabilities

6. **Enhanced Agent Metrics**
   - Update: `/analyze` command agents subcommand
   - Data: Average completion time, success/failure rates, common errors, tool usage patterns
   - Output: Comparative analysis with recommendations
   - Source: Parse `.claude/data/metrics/agents/*.jsonl`

### Component Interactions

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Workflow Improvement                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Templates (75% coverage)                                        │
│      │                                                           │
│      ├──► /plan-from-template ──► Plan Generation               │
│      │                              │                            │
│      │                              ▼                            │
│  /plan (with pre-analysis) ──► Complexity Analysis              │
│      │                              │                            │
│      │                              ▼                            │
│      └─────────────────────► Optimized Plan Structure           │
│                                      │                            │
│                                      ▼                            │
│                              /implement                           │
│                                      │                            │
│                                      ▼                            │
│                              Metrics Collection                   │
│                                      │                            │
│                                      ▼                            │
│                           analyze-metrics.sh                      │
│                                      │                            │
│                                      ▼                            │
│                           Performance Reports                     │
│                                      │                            │
│                                      ▼                            │
│                           Data-Driven Optimization               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Template → Plan Flow**
   - User selects template via `/plan-from-template` with category filter
   - Template variables substituted
   - Pre-analysis evaluates complexity
   - Plan generated with optimal structure

2. **Metrics → Insights Flow**
   - Commands/agents write JSONL metrics during execution
   - `analyze-metrics.sh` aggregates data monthly
   - Reports identify bottlenecks and optimization opportunities
   - Users make data-driven decisions on workflow improvements

3. **Documentation → Maintenance Flow**
   - Common patterns extracted to `command-patterns.md`
   - Commands reference shared documentation
   - Single source of truth for updates
   - Reduced context consumption for Claude

## Implementation Phases

### Phase 1: Template Library Expansion
**Objective**: Create 6 new templates to increase coverage from 20% to 75%
**Complexity**: Medium
**Estimated Time**: 8-10 hours

Tasks:
- [ ] Create `.claude/templates/debug-workflow.yaml` with investigation→report→fix pattern
  - Variables: `issue_description`, `affected_components`, `priority`
  - Phases: Investigation, Root Cause Analysis, Fix Implementation, Regression Testing
- [ ] Create `.claude/templates/documentation-update.yaml` for code change→doc sync
  - Variables: `changed_files`, `doc_scope`, `breaking_changes`
  - Phases: Impact Analysis, README Updates, Example Updates, Cross-Reference Verification
- [ ] Create `.claude/templates/test-suite.yaml` for TDD patterns
  - Variables: `module_name`, `test_type`, `coverage_target`
  - Phases: Test Structure Setup, Unit Tests, Integration Tests, Coverage Verification
- [ ] Create `.claude/templates/migration.yaml` for breaking change management
  - Variables: `migration_type`, `affected_apis`, `deprecation_period`
  - Phases: Deprecation Warnings, Migration Guide, Backward Compatibility Layer, Cutover
- [ ] Create `.claude/templates/research-report.yaml` for structured research
  - Variables: `topic`, `research_questions`, `depth_level`
  - Phases: Literature Review, Codebase Analysis, Best Practices, Recommendations
- [ ] Create `.claude/templates/refactor-consolidation.yaml` for code cleanup
  - Variables: `target_module`, `consolidation_strategy`, `risk_level`
  - Phases: Analysis, Refactoring Plan, Incremental Changes, Validation
- [ ] Add metadata to all templates: `category`, `complexity_level`, `estimated_time`
- [ ] Update `.claude/commands/plan-from-template.md` to show templates by category
  - Add category filtering logic
  - Display metadata in template listing
  - Update help text and examples

Testing:
```bash
# Verify template creation
ls -1 .claude/templates/*.yaml | wc -l  # Should be 10 (4 existing + 6 new)

# Test template validation
.claude/lib/parse-template.sh .claude/templates/debug-workflow.yaml

# Test category filtering in plan-from-template
/plan-from-template --list-categories
/plan-from-template --category debugging
```

Validation:
- [ ] All 6 new templates parse correctly
- [ ] Metadata fields present and valid
- [ ] Variables properly documented
- [ ] Phase structure follows project standards
- [ ] `/plan-from-template` lists templates by category

### Phase 2: Metrics Aggregation System
**Objective**: Enable automated metrics analysis for data-driven optimization
**Complexity**: Medium-High
**Estimated Time**: 6-8 hours

Tasks:
- [ ] Create `.claude/lib/analyze-metrics.sh` utility (~300 lines)
  - Function: `analyze_command_metrics()` - Parse command execution times, success rates
  - Function: `analyze_agent_metrics()` - Parse agent performance data
  - Function: `identify_bottlenecks()` - Find slowest phases, most common failures
  - Function: `calculate_template_effectiveness()` - Compare template vs manual plan times
  - Function: `generate_trend_report()` - Monthly trend analysis
  - Function: `generate_recommendations()` - Data-driven optimization suggestions
- [ ] Add JSONL parsing functions using `jq` for metric extraction
- [ ] Implement timeframe filtering (last 7/30/90 days)
- [ ] Create report generation with markdown output
- [ ] Add visualization helpers (ASCII charts for trends)
- [ ] Create `.claude/commands/analyze-metrics.md` command (~150 lines)
  - Accept timeframe argument (default: 30 days)
  - Output report to `specs/reports/NNN_metrics_analysis.md`
  - Include examples and usage documentation
- [ ] Integrate with existing `/analyze` command
  - Add `metrics` subcommand to `.claude/commands/analyze.md`
  - Route to `analyze-metrics.sh` utility
  - Update help text
- [ ] Add unit tests to `.claude/tests/test_metrics_analysis.sh`
  - Test JSONL parsing
  - Test timeframe filtering
  - Test report generation
  - Test bottleneck identification

Testing:
```bash
# Test utility functions
source .claude/lib/analyze-metrics.sh
analyze_command_metrics 30
analyze_agent_metrics 30

# Test command integration
/analyze metrics
/analyze metrics 7
/analyze metrics 90

# Run unit tests
.claude/tests/test_metrics_analysis.sh
```

Validation:
- [ ] Utility parses all existing JSONL metrics correctly
- [ ] Reports generated in proper markdown format
- [ ] Timeframe filtering works accurately
- [ ] Bottlenecks identified with supporting data
- [ ] Integration with `/analyze` command seamless
- [ ] All unit tests passing

### Phase 3: Complexity Pre-Analysis Integration
**Objective**: Add complexity analysis to `/plan` command for better initial plan structures
**Complexity**: Medium
**Estimated Time**: 4-5 hours

Tasks:
- [ ] Add `analyze_feature_description()` function to `.claude/lib/complexity-utils.sh`
  - Keyword analysis for task count estimation (create, update, refactor, etc.)
  - Dependency detection (external integrations, APIs, databases)
  - Architecture impact scoring (new modules vs extending existing)
  - Output: Complexity score (0-15), recommended structure, suggested phase count
- [ ] Update `.claude/commands/plan.md` to integrate pre-analysis (~100 lines)
  - Call `analyze_feature_description()` before plan generation
  - Display analysis results to user
  - Recommend starting structure (single file vs pre-expanded)
  - Suggest appropriate template if available
  - Show estimated phase count
- [ ] Add `--skip-analysis` flag for manual control
- [ ] Add analysis output format:
  ```
  Complexity Analysis:
  - Estimated complexity: 7.5 (Medium)
  - Recommended structure: Single file (expand if needed)
  - Suggested phases: 4-5
  - Matching templates: test-suite, crud-feature
  ```
- [ ] Update `.claude/tests/test_complexity_utils.sh` with new function tests
  - Test feature description parsing
  - Test keyword detection
  - Test complexity scoring
  - Test recommendation generation

Testing:
```bash
# Test complexity analysis function
source .claude/lib/complexity-utils.sh
analyze_feature_description "Add user authentication with OAuth and session management"

# Test plan command integration
/plan "Simple bug fix in parser"  # Should recommend simple structure
/plan "Implement microservices architecture with API gateway"  # Should recommend expanded

# Test skip flag
/plan --skip-analysis "Feature description"

# Run unit tests
.claude/tests/test_complexity_utils.sh
```

Validation:
- [ ] Complexity scoring accurate for various feature types
- [ ] Recommendations align with actual implementation needs
- [ ] Template suggestions relevant and helpful
- [ ] Skip flag bypasses analysis correctly
- [ ] All tests passing
- [ ] Analysis completes in <2 seconds

### Phase 4: Command Documentation Extraction
**Objective**: Reduce command file LOC by 30% through shared documentation
**Complexity**: Medium
**Estimated Time**: 5-6 hours

Tasks:
- [ ] Create `.claude/docs/command-patterns.md` (~800 lines) with sections:
  - Agent Invocation Patterns (Task block examples, agent selection)
  - Checkpoint Management Patterns (save, restore, resume examples)
  - Error Recovery Patterns (retry logic, escalation, rollback)
  - Artifact Referencing Patterns (pass-by-reference, cross-linking)
  - Testing Integration Patterns (phase testing, validation)
  - Progress Streaming Patterns (TodoWrite updates, status reporting)
- [ ] Extract common examples from top 3 commands:
  - `/orchestrate` (lines with Task blocks, checkpoint examples)
  - `/setup` (standards discovery, file creation patterns)
  - `/implement` (phase execution, test integration)
- [ ] Update all 20 command files to reference patterns:
  - Replace inline examples with: "See [Pattern Name](../docs/command-patterns.md#section)"
  - Keep command-specific examples inline
  - Maintain YAML frontmatter unchanged
- [ ] Priority command updates (largest LOC reduction):
  - `/orchestrate`: 2,476 → ~1,500 lines (remove ~976 lines)
  - `/setup`: 2,230 → ~1,400 lines (remove ~830 lines)
  - `/implement`: 1,553 → ~1,000 lines (remove ~553 lines)
- [ ] Update `.claude/README.md` to link to command-patterns.md
- [ ] Validate all pattern references are correct

Testing:
```bash
# Verify LOC reduction
wc -l .claude/commands/orchestrate.md  # Should be ~1,500
wc -l .claude/commands/setup.md        # Should be ~1,400
wc -l .claude/commands/implement.md    # Should be ~1,000
wc -l .claude/commands/*.md | tail -1   # Total should be ~6,200

# Verify pattern file created
wc -l .claude/docs/command-patterns.md  # Should be ~800

# Test that commands still work
/plan "Test feature"
/implement specs/plans/001_*.md --dry-run
```

Validation:
- [ ] Total command LOC reduced by ~2,000 lines (30% reduction)
- [ ] All pattern references link correctly
- [ ] No functionality lost in command execution
- [ ] Documentation clearer and more maintainable
- [ ] Single source of truth established

### Phase 5: Command Consolidation
**Objective**: Reduce command overlap by deprecating `/update` and clarifying responsibilities
**Complexity**: Low-Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Update `.claude/commands/update.md` with deprecation notice:
  - Add warning banner at top of file
  - Explain migration path to `/revise`
  - Set deprecation timeline (e.g., 30 days)
  - Provide examples of equivalent `/revise` commands
- [ ] Expand `.claude/commands/revise.md` to cover `/update` use cases:
  - Add section for simple content updates (former `/update` use case)
  - Clarify when to use `/revise` vs `/expand`
  - Add examples for both interactive and auto-mode
  - Update usage documentation
- [ ] Create command responsibility matrix in `.claude/docs/command-selection-guide.md`:
  ```markdown
  ## Plan Modification Commands

  | Task | Command | Reason |
  |------|---------|--------|
  | Add/modify tasks in phases | `/revise` | Content changes |
  | Split complex phase to file | `/expand` | Structural change |
  | Merge expanded phase back | `/collapse` | Structural simplification |
  | Update plan metadata | `/revise` | Content change |
  ```
- [ ] Update `.claude/README.md` command list:
  - Mark `/update` as deprecated
  - Update descriptions for `/revise`, `/expand`, `/collapse`
- [ ] Add migration guide section to `.claude/docs/command-selection-guide.md`
- [ ] Update any internal references to `/update` in other commands

Testing:
```bash
# Verify deprecation warning displays
/update --help

# Test revise covers update use cases
/revise specs/plans/001_*.md "Add task to Phase 2"

# Verify command selection guide created
cat .claude/docs/command-selection-guide.md | grep "Plan Modification"
```

Validation:
- [ ] Deprecation notice clear and helpful
- [ ] `/revise` handles all former `/update` use cases
- [ ] Command selection guide provides clear decision tree
- [ ] Documentation updated consistently
- [ ] No broken references to `/update`

### Phase 6: Enhanced Agent Performance Tracking
**Objective**: Add detailed agent metrics to `/analyze agents` command
**Complexity**: Medium
**Estimated Time**: 5-6 hours

Tasks:
- [ ] Update `.claude/commands/analyze.md` agents subcommand (~150 lines):
  - Add detailed performance analysis section
  - Parse `.claude/data/metrics/agents/*.jsonl` files
  - Calculate average completion time per agent
  - Calculate success/failure rates (% completed without errors)
  - Identify most common errors per agent
  - Analyze tool usage patterns (which tools used most)
  - Generate agent selection recommendations
- [ ] Implement comparative analysis output:
  ```markdown
  # Agent Performance Summary (Last 30 Days)

  ## code-writer
  - Average completion: 3.2 minutes
  - Success rate: 94% (47/50 tasks)
  - Most used tools: Edit (45%), Read (30%), Bash (15%)
  - Common errors:
    - Syntax validation (3 occurrences)
    - File not found (2 occurrences)
  - Recommendation: Best for implementation tasks, review syntax before commit

  ## test-specialist
  - Average completion: 1.8 minutes
  - Success rate: 98% (49/50 tasks)
  - Most used tools: Bash (60%), Read (25%), Grep (15%)
  - Common errors:
    - Test timeout (1 occurrence)
  - Recommendation: Highly reliable for testing, ensure test dependencies available
  ```
- [ ] Add timeframe filtering (7/30/90 days)
- [ ] Add agent comparison mode (compare 2+ agents side-by-side)
- [ ] Create helper functions in `.claude/lib/analyze-metrics.sh`:
  - `parse_agent_jsonl()` - Extract metrics from JSONL
  - `calculate_agent_stats()` - Compute averages and rates
  - `identify_common_errors()` - Group and count error types
  - `analyze_tool_usage()` - Calculate tool usage percentages
- [ ] Update `.claude/tests/test_analyze_command.sh` with agent metrics tests

Testing:
```bash
# Test agent analysis
/analyze agents
/analyze agents 7
/analyze agents --compare code-writer test-specialist

# Test utility functions
source .claude/lib/analyze-metrics.sh
parse_agent_jsonl .claude/data/metrics/agents/code-writer.jsonl
calculate_agent_stats "code-writer" 30

# Run unit tests
.claude/tests/test_analyze_command.sh
```

Validation:
- [ ] Agent metrics accurate and comprehensive
- [ ] Success rates calculated correctly
- [ ] Tool usage percentages sum to ~100%
- [ ] Recommendations data-driven and helpful
- [ ] Comparison mode works for multiple agents
- [ ] All tests passing

## Testing Strategy

### Unit Testing
- **Location**: `.claude/tests/`
- **Pattern**: `test_*.sh`
- **Coverage Target**: ≥80% for new code
- **New Tests Required**:
  - `test_template_parsing.sh` - Template validation and metadata
  - `test_metrics_analysis.sh` - Metrics aggregation functions
  - `test_complexity_preanalysis.sh` - Feature description analysis
  - `test_analyze_command.sh` - Enhanced agent metrics

### Integration Testing
- **Workflow Tests**: Test complete command chains
  - `/plan-from-template` → template selection → plan generation
  - `/analyze metrics` → report generation → file output
  - `/plan` with pre-analysis → complexity evaluation → recommendations
- **Command Integration**: Verify all updated commands work together
  - `/revise` replaces `/update` functionality
  - `/analyze agents` provides detailed metrics
  - Pattern references in commands resolve correctly

### Regression Testing
- **Baseline**: 93/93 tests currently passing
- **Requirement**: All existing tests must continue passing
- **Test Command**: `.claude/tests/run_all_tests.sh`
- **Critical Paths**:
  - Plan creation and implementation workflows
  - Checkpoint save/restore operations
  - Artifact referencing and cross-linking
  - Agent coordination patterns

### Performance Testing
- **Metrics Analysis**: Should complete in <5 seconds for 30 days
- **Complexity Pre-Analysis**: Should complete in <2 seconds
- **Template Parsing**: Should complete in <1 second per template
- **Command LOC Reduction**: Verify Claude processes faster (measure anecdotally)

## Documentation Requirements

### Files to Create
- `.claude/templates/debug-workflow.yaml`
- `.claude/templates/documentation-update.yaml`
- `.claude/templates/test-suite.yaml`
- `.claude/templates/migration.yaml`
- `.claude/templates/research-report.yaml`
- `.claude/templates/refactor-consolidation.yaml`
- `.claude/lib/analyze-metrics.sh`
- `.claude/commands/analyze-metrics.md`
- `.claude/docs/command-patterns.md`
- `.claude/docs/command-selection-guide.md`
- `.claude/tests/test_template_parsing.sh`
- `.claude/tests/test_metrics_analysis.sh`
- `.claude/tests/test_complexity_preanalysis.sh`
- `.claude/tests/test_analyze_command.sh`

### Files to Update
- `.claude/commands/plan-from-template.md` - Add category filtering
- `.claude/commands/plan.md` - Integrate complexity pre-analysis
- `.claude/commands/analyze.md` - Add metrics subcommand, enhance agents subcommand
- `.claude/commands/revise.md` - Expand to cover `/update` use cases
- `.claude/commands/update.md` - Add deprecation notice
- `.claude/commands/orchestrate.md` - Extract documentation, add pattern references
- `.claude/commands/setup.md` - Extract documentation, add pattern references
- `.claude/commands/implement.md` - Extract documentation, add pattern references
- All 17 other command files - Replace inline examples with pattern references
- `.claude/lib/complexity-utils.sh` - Add `analyze_feature_description()` function
- `.claude/README.md` - Update command list, add links to new guides
- `.claude/templates/README.md` - Document new templates

### Documentation Standards
- Follow project documentation policy (no historical markers)
- Use Unicode box-drawing for diagrams (no ASCII art)
- No emojis in file content
- Update modification dates
- Maintain existing structure and navigation
- Cross-reference related documentation

## Dependencies

### External Dependencies
- `jq` - JSON/JSONL parsing for metrics analysis (already available)
- `dialog` or `whiptail` - Optional for future interactive progress (not in this plan)
- Bash 4.0+ - For associative arrays and modern features

### Internal Dependencies
- `.claude/lib/parse-template.sh` - Template parsing (existing)
- `.claude/lib/complexity-utils.sh` - Complexity scoring (existing)
- `.claude/lib/checkpoint-utils.sh` - Checkpoint management (existing)
- `.claude/data/metrics/` directory - Metrics JSONL files (existing)

### Prerequisite Checks
```bash
# Verify jq available
command -v jq >/dev/null 2>&1 || echo "WARNING: jq not found"

# Verify metrics directory exists
ls -d .claude/data/metrics/ >/dev/null 2>&1 || mkdir -p .claude/data/metrics/

# Verify test framework available
[ -f .claude/tests/run_all_tests.sh ] || echo "WARNING: Test framework missing"
```

## Risk Assessment

### High Risk Areas
1. **Breaking Command Changes** (Probability: Low, Impact: High)
   - Risk: Updating 20 command files could introduce syntax errors
   - Mitigation: Test each command after updates, maintain git commits per phase
   - Rollback: Git revert to previous phase if issues detected

2. **Metrics Parsing Failures** (Probability: Medium, Impact: Medium)
   - Risk: JSONL format changes could break parsing logic
   - Mitigation: Add schema validation, test with real metrics files
   - Fallback: Graceful degradation with warning messages

3. **Template Validation Errors** (Probability: Low, Impact: Medium)
   - Risk: Invalid YAML in new templates
   - Mitigation: Test all templates with parse-template.sh before commit
   - Validation: Pre-commit hook for template validation

### Medium Risk Areas
1. **Test Coverage Gaps** (Probability: Medium, Impact: Medium)
   - Risk: New functionality not fully covered by tests
   - Mitigation: Write tests concurrently with implementation
   - Target: ≥80% coverage for new code

2. **Documentation Sync** (Probability: Medium, Impact: Low)
   - Risk: Pattern references broken after extraction
   - Mitigation: Validate all links before commit
   - Tool: Use grep to find broken references

### Low Risk Areas
1. **Performance Regression** (Probability: Low, Impact: Low)
   - Risk: Metrics analysis too slow
   - Mitigation: Profile with real data, optimize queries
   - Target: <5 seconds for 30-day analysis

2. **User Confusion** (Probability: Low, Impact: Low)
   - Risk: Deprecation of `/update` causes workflow disruption
   - Mitigation: Clear migration guide, 30-day deprecation period
   - Communication: Update README prominently

## Rollback Plan

### Phase-Level Rollback
Each phase is git-committed separately, allowing rollback to any previous phase:
```bash
# Rollback to previous phase
git log --oneline | head -6  # Show last 6 commits (one per phase)
git revert <commit-hash>     # Revert specific phase
```

### Critical File Backups
Before making changes to critical files:
```bash
# Backup critical commands before updates
cp .claude/commands/plan.md .claude/commands/plan.md.backup
cp .claude/commands/analyze.md .claude/commands/analyze.md.backup
cp .claude/lib/complexity-utils.sh .claude/lib/complexity-utils.sh.backup
```

### Validation Checkpoints
After each phase, verify system still works:
```bash
# Quick validation
.claude/tests/run_all_tests.sh  # All tests must pass
/plan "Test feature"             # Plan command must work
/analyze --help                  # Analyze command must work
```

## Implementation Notes

### Phase Execution Order
Phases are designed to be executed sequentially with each phase building on previous work:
1. **Phase 1 (Templates)**: Foundation for better planning workflows
2. **Phase 2 (Metrics)**: Enables data-driven optimization
3. **Phase 3 (Pre-Analysis)**: Leverages templates and complexity utils
4. **Phase 4 (Documentation)**: Cleans up commands before consolidation
5. **Phase 5 (Consolidation)**: Simplifies command ecosystem
6. **Phase 6 (Agent Metrics)**: Completes metrics system with agent tracking

### Git Commit Strategy
One commit per phase with descriptive messages:
```
Phase 1: Expand template library to 75% coverage (6 new templates)
Phase 2: Implement metrics aggregation system with automated analysis
Phase 3: Integrate complexity pre-analysis into /plan command
Phase 4: Extract command documentation to reduce LOC by 30%
Phase 5: Deprecate /update command and clarify command responsibilities
Phase 6: Enhance /analyze agents with detailed performance tracking
```

### Testing Cadence
- After each task: Run relevant unit tests
- After each phase: Run full test suite (`.claude/tests/run_all_tests.sh`)
- After all phases: Full integration testing and validation

### Success Metrics Measurement
After implementation completion, measure:
```bash
# Template coverage
ls -1 .claude/templates/*.yaml | wc -l  # Should be 10 (75% coverage estimate)

# LOC reduction
wc -l .claude/commands/*.md | tail -1  # Should be ~6,200 (was 8,700)

# Test coverage
.claude/tests/run_all_tests.sh | grep "PASSED"  # Should be 93+/93+ tests

# Metrics functionality
/analyze metrics 30  # Should generate report successfully
/analyze agents      # Should show detailed performance data
```

## Future Enhancements (Not in This Plan)

The following optimizations are deferred for future implementation:
- Interactive progress visualization (TUI with `dialog`)
- Artifact cleanup utility (automated archival after 60 days)
- Artifact relationship visualization (dependency graphs)
- Enhanced artifact metadata (status, tags, dependencies)
- Workflow presets (feature-full, bugfix-quick, refactor-safe)
- Template discovery in `/list` command
- Checkpoint schema versioning documentation

These enhancements are documented in `.claude/DEFERRED_TASKS.md` and can be planned in future optimization cycles.

## Notes

### Design Philosophy Alignment
This plan follows the project's clean-break refactor philosophy:
- Deprecating `/update` rather than maintaining compatibility
- Creating new shared documentation rather than duplicating
- Focusing on current implementation quality over historical patterns

### Backward Compatibility
- `/update` deprecated with 30-day migration period
- All other commands maintain backward compatibility
- Existing templates continue to work unchanged
- Metrics JSONL format unchanged (additive only)

### Maintenance Considerations
- Shared documentation in `command-patterns.md` reduces future updates
- Template metadata enables better discovery and filtering
- Metrics system provides ongoing optimization insights
- Command consolidation simplifies mental model

### Performance Characteristics
- Complexity pre-analysis adds ~1-2 seconds to `/plan` execution
- Metrics analysis adds ~3-5 seconds for 30-day reports
- Template parsing overhead negligible (<1 second)
- Command LOC reduction should improve Claude processing speed

---

This implementation plan provides a comprehensive roadmap for optimizing the Claude Code .claude/ system with measurable outcomes and clear validation criteria for each phase.

